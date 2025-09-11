# LFK Infrastructure

## Prerequisites

### Tools

* [google-cloud-cli](https://cloud.google.com/sdk/docs/install)
* [k3s](https://docs.k3s.io/quick-start)
* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)

### Service account

#### Create account

NOTE: One time action

```bash
PROJECT_ID=[gcp project id]
GCP_SA=sa-external-secrets
gcloud iam service-accounts create ${GCP_SA}
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role="roles/secretmanager.secretAccessor" \
  --member "serviceAccount:${GCP_SA}@${PROJECT_ID}.iam.gserviceaccount.com"
```

#### Create key

```bash
cp charts/k3s/secret-manager-account.yaml .
gcloud iam service-accounts keys create key.json \
  --iam-account=${GCP_SA}@${PROJECT_ID}.iam.gserviceaccount.com >> secret-manager-account.yaml
```

## Setup

### Configure k3s

```bash
cp /etc/rancher/k3s/k3s.yaml .kube/config
cp charts/k3s/traefik-config.yaml charts/k3s/storageclass.yaml  /var/lib/rancher/k3s/server/manifests/
```

### Prepare installation

```bash
kubectl create ns core
kubectl apply -f secret-manager-account.yaml --namespace core
rm secret-manager-account.yaml
```

### Install Argo CD

Inspired by the following [guide](https://www.arthurkoziel.com/setting-up-argocd-with-helm/).

```bash

kubectl create ns argocd
helm install argo-cd charts/argo-cd/ --namespace argocd
helm template charts/root-app/ | kubectl apply --namespace argocd -f -
```

Apply `argocd-ingress.yaml` TODO: add to argocd chart

#### Update admin password

1. Get password: `kubectl get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
1. Login to webui, change password
1. Delete initial password: `kubectl delete secret -l owner=helm,name=argo-cd`
