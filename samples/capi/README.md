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

<!-- https://github.com/kubernetes-sigs/cluster-api-provider-gcp/blob/main/test/e2e/data/infrastructure-gcp/cluster-template-ci-with-creds.yaml
https://cluster-api-gcp.sigs.k8s.io/self-managed/provision
https://github.com/k3s-io/cluster-api-k3s/blob/main/samples/azure/k3s-template.yaml
https://github.com/rancher/terraform-provider-rancher2
https://github.com/rancher/terraform-aws-rke2
https://github.com/orgs/rancher/repositories?q=terraform
https://github.com/rancherfederal/rke2-aws-tf/blob/master/main.tf -->
