# LFK Infrastructure

## Get Started

### Prerequisites

* [k3s](https://docs.k3s.io/quick-start)
* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)

### Configuration

Copy `/etc/rancher/k3s/k3s.yaml` to `.kube/config`

### Install Argo CD

Getting started [documentation](https://argo-cd.readthedocs.io/en/stable/getting_started/).

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

```
