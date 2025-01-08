# Cluster API

```bash
clusterctl config repositories

cat <<EOF > clusterctl.yaml
GCP_PROJECT: cluster-api-gcp-project
GCP_REGION: us-east4
GCP_NETWORK_NAME: default
WORKER_MACHINE_COUNT: 1
EOF
clusterctl generate cluster gke-capi-bthomas-demo --flavor gke -i gcp --config clusterctl.yaml  > capi-gke-quickstart.yaml
```
