# LFK Infrastructure

## Prerequisites

### Tools

* [google-cloud-cli](https://cloud.google.com/sdk/docs/install)
* [k3s](https://docs.k3s.io/quick-start)
* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
* [GCP Service Account](#service-account)

## Setup

This project uses a setup script to configure the k3s environment. The script is idempotent, meaning it can be run multiple times without causing issues.

### Run the script

To set up the environment, run the following command:

```bash
./setup_k3s.sh <environment>
```

Replace `<environment>` with one of the following:

* `dz`
* `cloud`
* `development`

For example:

```bash
./setup_k3s.sh development
```

The script will perform the following steps:
1.  Fetch the GCP service account key.
2.  Configure k3s with the correct container registry, storage class and Traefik configuration.
3.  Set up kubectl access.
4.  Prepare Secret Manager access for Kubernetes.
5.  Install Argo CD and its dependencies.
6.  Apply the root application for the specified environment.

After the script has finished, it will output the command to get the Argo CD admin password.


## Service account

`NOTE:` One time action, only here as reference.

```bash

PROJECT_ID=bitnami-ch3rudc
GCP_SA=sa-k3s

# Create Account
gcloud iam service-accounts create ${GCP_SA}

# Add bindings
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role="roles/secretmanager.secretAccessor" \
  --member "serviceAccount:${GCP_SA}@${PROJECT_ID}.iam.gserviceaccount.com"
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role="roles/artifactregistry.reader" \
  --member "serviceAccount:${GCP_SA}@${PROJECT_ID}.iam.gserviceaccount.com"
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role="roles/storage.objectUser" \
  --member "serviceAccount:${GCP_SA}@${PROJECT_ID}.iam.gserviceaccount.com"

# Create secret
gcloud iam service-accounts keys create key.json \
  --iam-account=${GCP_SA}@${PROJECT_ID}.iam.gserviceaccount.com
gcloud secrets versions add gcp-service-account --data-file key.json
```
