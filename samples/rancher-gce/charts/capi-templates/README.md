# Cluster API (CAPI) Templates Helm Chart

This chart will simplify the use of CAPI to manage your Kubernetes clusters.

## Quick start

### Setup

Add the Helm repository:

```bash
helm repo add devpro https://devpro.github.io/helm-charts
helm repo update
```

### GKE

Generate template for GKE (Google Cloud Managed Kubernetes cluster):

```bash
cat <<EOF > values_gke.yaml
name: gke-capi-$USER-demo
type: gke
googlecloud:
  project: $GCLOUD_PROJECT_ID
  region: $GCLOUD_REGION
  vpc: $GCLOUD_VPC
  zone: $GCLOUD_ZONE
  subnet:
    name: $GCLOUD_SUBNET
EOF

helm template capi-gke-demo . -f values.yaml -f values_gke.yaml > temp.yaml

helm upgrade --install capi-gke-demo . -f values.yaml -f values_gke.yaml --namespace demo --create-namespace

kubectl get cluster -n demo

clusterctl describe cluster gke-capi-bthomas-demo -n demo
```

Clean-up:

```bash
helm delete capi-gke-demo -n demo
kubectl delete ns demo
```
