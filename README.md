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
