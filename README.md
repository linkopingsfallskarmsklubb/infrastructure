# LFK Infrastructure

## Prerequisites

### Tools

* [google-cloud-cli](https://cloud.google.com/sdk/docs/install)
* [k3s](https://docs.k3s.io/quick-start) `curl -sfL https://get.k3s.io | sh -`
* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)

## Setup

This project uses a setup script to configure the k3s environment. You
need to have access to the GCP project and have tools above installed.

### Run the script

To set up the environment, run the following command:

```bash
./k3s/setup_k3s.sh <environment>
```

Replace `<environment>` with one of the following:

* `dz`: Runs myqsl, skywinone and other on prem services
* `cloud`: Runs insidan, authentication and other cloud services
* `development`: Runs everything in same environment for development

For example:

```bash
./k3s/setup_k3s.sh development
```

The script will perform the following steps:

1. Fetch the GCP service account key.
2. Configure k3s with the correct container registry, storage class and Traefik configuration.
3. Set up kubectl access.
4. Prepare Secret Manager access for Kubernetes.
5. Install Argo CD and its dependencies.
6. Apply the root application for the specified environment.

## Cleanup

To clean up the installation, all you have to do is remove k3s from your system:

```bash
/usr/local/bin/k3s-uninstall.sh
```

## Environment Management

This project uses the "App of Apps" pattern. The root application for each environment is defined in `clusters/<environment>/root-app.yaml` and tracks the `main` branch of this repository.

### Tagging Infrastructure Releases

Before updating an environment to a new version, you must first create a new release tag using the GitHub Actions workflow.

1. Go to the **Actions** tab in the GitHub repository.
2. Select the **infra-tag** workflow.
3. Click **Run workflow** and ensure the `main` branch is selected.

This workflow uses [GitVersion](https://gitversion.net/) to calculate the next semantic version based on your commit history and creates a new tag in the format `infra/X.Y.Z` (e.g., `infra/1.0.0`). Once the tag is created, you can use it in the environment's `values.yaml` file as described above.

### Bumping Versions

To update an environment (e.g., `cloud`) to a specific state (e.g., a release tag like `infra/1.0.0` or a specific commit hash), update the `revision` value in the environment's `values.yaml` file:

**File:** `clusters/cloud/manifests/values.yaml`
```yaml
revision: infra/1.0.0
```

Once this change is pushed to the `main` branch, Argo CD will automatically update all applications in that environment to pull their charts and configurations from that specific revision.

### Environment-Specific Configurations

* **Cloud:** `clusters/cloud/manifests/values.yaml`
* **Dropzone (DZ):** `clusters/dz/manifests/values.yaml`
* **Development:** `clusters/development/manifests/values.yaml`
