# LFK Infrastructure

## Prerequisites

### Tools

* [google-cloud-cli](https://cloud.google.com/sdk/docs/install)
* [k3s](https://docs.k3s.io/quick-start)
* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)

### Service account

```bash
PROJECT_ID=bitnami-ch3rudc
GCP_SA=sa-k3s
```

#### Create Account

`NOTE:` One time action, only here as reference.

```bash

gcloud iam service-accounts create ${GCP_SA}
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role="roles/secretmanager.secretAccessor" \
  --member "serviceAccount:${GCP_SA}@${PROJECT_ID}.iam.gserviceaccount.com"
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role="roles/artifactregistry.reader" \
  --member "serviceAccount:${GCP_SA}@${PROJECT_ID}.iam.gserviceaccount.com"
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role="roles/storage.objectUser" \
  --member "serviceAccount:${GCP_SA}@${PROJECT_ID}.iam.gserviceaccount.com"

```

#### Create key

```bash
gcloud iam service-accounts keys create key.json \
  --iam-account=${GCP_SA}@${PROJECT_ID}.iam.gserviceaccount.com
```

## Setup

### Configure k3s

```bash
# GCP Artifact Registry
cp k3s/registries.yaml . && cat key.json | sed 's/^/        /' >> registries.yaml
sudo mv registries.yaml /etc/rancher/k3s/registries.yaml

# Persistant storage class
sudo cp k3s/storageclass.yaml  /var/lib/rancher/k3s/server/manifests/

# Traefik config
sudo cp k3s/traefik-config.yaml  /var/lib/rancher/k3s/server/manifests/

# kubectl access
sudo cp /etc/rancher/k3s/k3s.yaml .kube/config

sudo systemctl restart k3s
```

### Prepare Secret Manager access

```bash
# Create Kubernetes secret
cp k3s/secret-manager-account.yaml .
cat key.json | sed 's/^/    /' >> secret-manager-account.yaml

# Apply
kubectl create ns core
kubectl apply -f secret-manager-account.yaml --namespace core

# Cleanup
rm key.json secret-manager-account.yaml
```

### Install Argo CD

Inspired by the following [guide](https://www.arthurkoziel.com/setting-up-argocd-with-helm/).

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm dependency update charts/argo-cd/
kubectl create ns argocd
helm install argo-cd charts/argo-cd/ --namespace argocd
helm template charts/root-app/ | kubectl apply --namespace argocd -f -
```

Apply `argocd-ingress.yaml` TODO: add to argocd chart

#### Update admin password

1. Get password: `kubectl get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" --namespace argocd | base64 -d`
1. Login to webui, change password
1. Delete initial password: `kubectl delete secret -l owner=helm,name=argo-cd`
