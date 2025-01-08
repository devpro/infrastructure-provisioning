# Cluster API (CAPI) Templates Helm Chart

This chart will simplify the use of CAPI to manage your Kubernetes clusters.

## Quick start

Add the Helm repository:

```bash
helm repo add devpro https://devpro.github.io/helm-charts
helm repo update
```

Generate template for GKE (Google Cloud Managed Kubernetes cluster):

```bash
cat <<EOF > values_gke.yaml
name: gke-capi-$USER-demo
type: gke
googlecloud:
  project: $GCLOUD_PROJECT_ID
  region: $GCLOUD_REGION
  vpc: $GCLOUD_VPC
EOF

helm template capi-gke-demo . -f values.yaml -f values_gke.yaml > temp.yaml

helm upgrade --install capi-gke-demo . -f values.yaml -f values_gke.yaml --namespace demo --create-namespace


```

Install the app with default settings:

```bash
helm upgrade --install capi-templates devpro/capi-templates --namespace demo --create-namespace
```

Look at [values.yaml](values.yaml) for the configuration.

Clean-up:

```bash
helm delete capi-templates -n demo
kubectl delete ns demo
```
