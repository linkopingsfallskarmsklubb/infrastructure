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

# 1. Get service account key
if [ ! -f "key.json" ]; then
  info "Fetching GCP service account key..."
  gcloud secrets versions access latest --secret=gcp-service-account --project=$PROJECT_ID --out-file key.json
else
  info "key.json already exists, skipping download."
fi

# 2. Configure k3s
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
  if [ ! -f "$TRAEFIK_CONFIG_DST" ]; then
    info "Configuring Traefik for $ENV environment..."
    sudo cp "$TRAEFIK_CONFIG_SRC" "$TRAEFIK_CONFIG_DST"
  else
    info "Traefik config already exists, skipping."
  fi
else
  warning "Traefik config for $ENV not found at $TRAEFIK_CONFIG_SRC"
fi

info "Restarting k3s to apply changes..."
sudo systemctl restart k3s

# 3. Kubectl access
KUBECONFIG_DIR="$HOME/.kube"
KUBECONFIG_FILE="$KUBECONFIG_DIR/config"
if [ ! -f "$KUBECONFIG_FILE" ]; then
  info "Setting up kubectl access..."
  mkdir -p "$KUBECONFIG_DIR"
  sudo cp /etc/rancher/k3s/k3s.yaml "$KUBECONFIG_FILE"
  sudo chown $USER:$USER "$KUBECONFIG_FILE"
else
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

if ! kubectl get ns argocd >/dev/null 2>&1; then
  info "Creating 'argocd' namespace..."
  kubectl create ns argocd
else
  info "'argocd' namespace already exists."
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

if ! helm status argo-cd -n argocd >/dev/null 2>&1; then
  info "Installing Argo CD with Helm..."
  helm install argo-cd charts/argo-cd/ --namespace argocd --create-namespace
else
  info "Argo CD already installed."
fi

ROOT_APP_FILE="clusters/$ENV/root-app.yaml"
if [ -f "$ROOT_APP_FILE" ]; then
  info "Applying root app for $ENV environment..."
  kubectl apply -f "$ROOT_APP_FILE" -n argocd
else
  warning "Root app for $ENV not found at $ROOT_APP_FILE"
fi

# Cleanup
info "Cleaning up temporary files..."
rm -f key.json

info "Setup complete for environment: $ENV"
info "You can now get the Argo CD admin password with:"
echo "kubectl get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' --namespace argocd | base64 -d"
