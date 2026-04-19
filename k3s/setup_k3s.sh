#!/bin/bash

# Exit on error
set -e

# --- Helper functions ---

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to print info messages
info() {
  echo "[INFO] $1"
}

# Function to print warning messages
warning() {
  echo "[WARNING] $1"
}

# --- Main script ---

# Check for environment parameter
if [ -z "$1" ]; then
  echo "Usage: $0 <environment>"
  echo "Available environments: dz, cloud, development"
  exit 1
fi

ENV=$1
PROJECT_ID="bitnami-ch3rudc"
GCP_SA="sa-k3s"

info "Starting k3s setup for environment: $ENV"

# Check for required tools
for cmd in gcloud kubectl helm; do
  if ! command_exists "$cmd"; then
    warning "Command not found: $cmd. Please install it first."
    exit 1
  fi
done

if [ "$ENV" == "development" ]; then
  if ! command_exists mkcert; then
    warning "mkcert not found. Please install it for local development TLS support."
    exit 1
  fi
  info "Ensuring mkcert CA is installed in the system trust store..."
  mkcert -install
fi

# 1. Get service account key
if [ ! -f "key.json" ]; then
  info "Fetching GCP service account key..."
  gcloud secrets versions access latest --secret=gcp-service-account --project=$PROJECT_ID --out-file key.json
else
  info "key.json already exists, skipping download."
fi

# 2. Configure k3s
if [ "$ENV" == "development" ]; then
  info "Generating local certificates with mkcert..."
  mkdir -p certs
  mkcert -cert-file certs/local-cert.pem -key-file certs/local-key.pem "*.linkopingsfallskarmsklubb.localhost" linkopingsfallskarmsklubb.localhost
fi

REGISTRIES_FILE="/etc/rancher/k3s/registries.yaml"
if [ ! -f "$REGISTRIES_FILE" ]; then
  info "Configuring k3s container registry..."
  cp k3s/registries.yaml . && cat key.json | sed 's/^/        /' >>registries.yaml
  sudo mv registries.yaml "$REGISTRIES_FILE"
else
  info "k3s registries file already exists, skipping."
fi

STORAGECLASS_FILE="/var/lib/rancher/k3s/server/manifests/storageclass.yaml"
if [ ! -f "$STORAGECLASS_FILE" ]; then
  info "Creating k3s persistent storage class..."
  sudo cp k3s/storageclass.yaml "$STORAGECLASS_FILE"
else
  info "k3s storage class already exists, skipping."
fi

TRAEFIK_CONFIG_SRC="k3s/$ENV/traefik-config.yaml"
TRAEFIK_CONFIG_DST="/var/lib/rancher/k3s/server/manifests/traefik-config.yaml"
if [ -f "$TRAEFIK_CONFIG_SRC" ]; then
  info "Configuring Traefik for $ENV environment..."
  sudo cp "$TRAEFIK_CONFIG_SRC" "$TRAEFIK_CONFIG_DST"
else
  warning "Traefik config for $ENV not found at $TRAEFIK_CONFIG_SRC"
fi

if [ "$ENV" == "development" ]; then
  info "Applying default TLS certificate for Traefik..."
  TRAEFIK_DEFAULT_CERT_SRC="k3s/development/traefik-default-cert.yaml"
  TRAEFIK_DEFAULT_CERT_DST="/var/lib/rancher/k3s/server/manifests/traefik-default-cert.yaml"
  if [ -f "$TRAEFIK_DEFAULT_CERT_SRC" ]; then
    sudo cp "$TRAEFIK_DEFAULT_CERT_SRC" "$TRAEFIK_DEFAULT_CERT_DST"
  fi

  info "Applying global HTTP to HTTPS redirect..."
  TRAEFIK_REDIRECT_SRC="k3s/development/traefik-global-redirect.yaml"
  TRAEFIK_REDIRECT_DST="/var/lib/rancher/k3s/server/manifests/traefik-global-redirect.yaml"
  if [ -f "$TRAEFIK_REDIRECT_SRC" ]; then
    sudo cp "$TRAEFIK_REDIRECT_SRC" "$TRAEFIK_REDIRECT_DST"
  fi
fi

info "Restarting k3s to apply changes..."
sudo systemctl restart k3s

if [ "$ENV" == "development" ]; then
  info "Force-restarting Traefik to apply configuration..."
  # Wait a bit for k3s to be ready
  sleep 5
  kubectl delete pod -n kube-system -l app.kubernetes.io/name=traefik --force --grace-period=0 || true
fi

# 3. Kubectl access
KUBECONFIG_DIR="$HOME/.kube"
KUBECONFIG_FILE="$KUBECONFIG_DIR/config"
if [ ! -f "$KUBECONFIG_FILE" ]; then
  info "Setting up kubectl access..."
  mkdir -p "$KUBECONFIG_DIR"
  sudo cp /etc/rancher/k3s/k3s.yaml "$KUBECONFIG_FILE"
  sudo chown $USER:$USER "$KUBECONFIG_FILE"
else
  # Avoid interactive prompt if possible, but keep current logic
  read -p "kubeconfig file already exists. Overwrite? (y/N): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    info "Overwriting existing kubeconfig."
    sudo cp /etc/rancher/k3s/k3s.yaml "$KUBECONFIG_FILE"
    sudo chown $USER:$USER "$KUBECONFIG_FILE"
  else
    info "kubectl config already exists, skipping."
  fi
fi

if [ "$ENV" == "development" ]; then
  info "Applying local TLS certificate to k3s cluster..."
  kubectl create secret tls mkcert-wildcard-cert --cert=certs/local-cert.pem --key=certs/local-key.pem -n kube-system --dry-run=client -o yaml | kubectl apply -f -
  
  info "Exporting mkcert root CA and creating secrets..."
  MKCERT_CAROOT=$(mkcert -CAROOT)
  for ns in apps auth argocd; do
    kubectl create ns $ns --dry-run=client -o yaml | kubectl apply -f -
    kubectl create secret tls mkcert-wildcard-cert --cert=certs/local-cert.pem --key=certs/local-key.pem -n $ns --dry-run=client -o yaml | kubectl apply -f -
    kubectl create secret generic mkcert-ca-cert --from-file=ca.crt="$MKCERT_CAROOT/rootCA.pem" -n $ns --dry-run=client -o yaml | kubectl apply -f -
    if [ "$ns" == "auth" ]; then
      kubectl create secret tls authelia-tls --cert=certs/local-cert.pem --key=certs/local-key.pem -n $ns --dry-run=client -o yaml | kubectl apply -f -
    fi
  done
  info "Detecting Traefik ClusterIP for internal routing..."
  TRAEFIK_IP=$(kubectl get svc traefik -n kube-system -o jsonpath='{.spec.clusterIP}')
  info "Traefik ClusterIP detected: $TRAEFIK_IP"
fi

# 4. Prepare Secret Manager access
info "Preparing Secret Manager access..."
if ! kubectl get ns core >/dev/null 2>&1; then
  info "Creating 'core' namespace..."
  kubectl create ns core
else
  info "'core' namespace already exists."
fi

if ! kubectl get secret gcp-sa-key --namespace core >/dev/null 2>&1; then
  info "Creating 'gcp-sa-key' secret in 'core' namespace..."
  cp k3s/secret-manager-account.yaml .
  cat key.json | sed 's/^/    /' >>secret-manager-account.yaml
  kubectl apply -f secret-manager-account.yaml --namespace core
  rm secret-manager-account.yaml
else
  info "'gcp-sa-key' secret in 'core' namespace already exists."
fi

if ! kubectl get secret gcp-sa-key --namespace argocd >/dev/null 2>&1; then
  info "Creating 'gcp-sa-key' secret in 'argocd' namespace..."
  # Re-use the same file, but apply to a different namespace
  cp k3s/secret-manager-account.yaml .
  cat key.json | sed 's/^/    /' >>secret-manager-account.yaml
  kubectl apply -f secret-manager-account.yaml --namespace argocd
  rm secret-manager-account.yaml
else
  info "'gcp-sa-key' secret in 'argocd' namespace already exists."
fi

# 5. Install Argo CD
info "Installing Argo CD..."
if ! helm repo list | grep -q "https://argoproj.github.io/argo-helm"; then
  info "Adding Argo CD Helm repo..."
  helm repo add argo https://argoproj.github.io/argo-helm
else
  info "Argo CD Helm repo already added."
fi

info "Updating Helm dependencies..."
helm dependency update charts/argo-cd/

if ! kubectl get crd/externalsecrets.external-secrets.io >/dev/null 2>&1; then
  info "Applying External Secrets CRDs..."
  kubectl apply -f "https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/crds/bundle.yaml" --server-side --force-conflicts
else
  info "External Secrets CRDs already applied."
fi

info "Installing/Updating Argo CD with Helm..."
ARGOCD_VALUES_ARGS="-f charts/argo-cd/values.yaml"
if [ -f "charts/argo-cd/values/$ENV.yaml" ]; then
  ARGOCD_VALUES_ARGS="$ARGOCD_VALUES_ARGS -f charts/argo-cd/values/$ENV.yaml"
fi

helm upgrade --install argo-cd charts/argo-cd/ --namespace argocd --create-namespace $ARGOCD_VALUES_ARGS

ROOT_APP_FILE="clusters/$ENV/root-app.yaml"
if [ -f "$ROOT_APP_FILE" ]; then
  info "Applying root app for $ENV environment..."
  kubectl apply -f "$ROOT_APP_FILE" -n argocd
  
  if [ "$ENV" == "development" ]; then
    info "Patching root app with dynamic Traefik IP..."
    kubectl patch app root-development -n argocd --type merge -p "{\"spec\": {\"source\": {\"helm\": {\"values\": \"global:\\n  traefikIp: $TRAEFIK_IP\"}}}}"
  fi
else
  warning "Root app for $ENV not found at $ROOT_APP_FILE"
fi

# Cleanup
info "Cleaning up temporary files..."
rm -f key.json

info "Setup complete for environment: $ENV"

if [ "$ENV" == "development" ]; then
  info "Please add the following entries to your /etc/hosts file:"
  echo "127.0.0.1  auth.linkopingsfallskarmsklubb.localhost"
  echo "127.0.0.1  insidan.linkopingsfallskarmsklubb.localhost"
  echo "127.0.0.1  lldap.linkopingsfallskarmsklubb.localhost"
  echo "127.0.0.1  argocd.linkopingsfallskarmsklubb.localhost"
fi

info "You can now get the Argo CD admin password with:"
echo "kubectl get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' --namespace argocd | base64 -d"
