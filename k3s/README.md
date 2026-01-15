# Service account creation

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
