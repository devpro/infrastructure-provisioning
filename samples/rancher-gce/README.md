# Rancher on Google Cloud Compute Engine (VM)

In this scenario, we'll see how we can use Rancher to manage Kubernetes clusters in Google Cloud.

## Requirements

### Google Cloud SDK

If not already installed, download and install [Google Cloud SDK](https://cloud.google.com/sdk/) on your machine:

```bash
gcloud version
```

> **Google Cloud SDK** is a set of libraries and tools for interacting with Google Cloud products and services

### Google Cloud account

Authentify from the terminal:

```bash
gcloud auth login
```

> If your organization has a landing zone, make sure to log in with the right user (your Google account may not be the one to be used to Google Cloud)

### Google Cloud Service Account

From the browser (see [Create a Service Account](https://cluster-api-gcp.sigs.k8s.io/quick-start#create-a-service-account)):

- Go to [IAM & Admin / Service Accounts](https://console.cloud.google.com/projectselector/iam-admin/serviceaccounts)
- Switch to your Google Cloud account (may be different from your Google Workspace account)
- Select the project
- Create a service account if it does not already exist
- In Permissions tab, make sure to have/add the roles:
  - [Editor](https://cloud.google.com/iam/docs/understanding-roles#editor)
  - For GKE: [Service Account Token Creator](https://cloud.google.com/iam/docs/understanding-roles#iam.serviceAccountTokenCreator) (see [PR #1371](https://github.com/kubernetes-sigs/cluster-api-provider-gcp/pull/1371))
- In Keys tab, create a key and download the json file

> Google Cloud Service Account is needed manage resources on Google Cloud

### Script library

Source the local files from the terminal:

```bash
. ./scripts/index.sh
```

> This repository holds many shell functions to help running the scenario

### Configuration

Create an .env file with your variables:

```bash
GCLOUD_PROJECT_ID='your-project-id'
GCLOUD_REGION='europe-west1'
GCLOUD_SERVICEACCOUNT_KEYSFILE='/path/to/keys/somefile.json'
GCLOUD_SUBNET='subnet-xxx-demo'
GCLOUD_VPC='vpc-xxx-demo'
GCLOUD_ZONE='europe-west1-b'
KUBECONFIG=samples/rancher-gce/config/management-k3s.yaml
MANAGEMENT_STATICIP_NAME='ip-xxx-management'
MANAGEMENT_VM_NAME='vm-xxx-management'
RANCHER_PASSWORD='some-password'
```

Apply the .env file:

```bash
source samples/rancher-gce/.env
```

Set dynamic variables:

```bash
MY_IP=$(linux_get_myip)
GCP_B64ENCODED_CREDENTIALS=$(cat $GCLOUD_SERVICEACCOUNT_KEYSFILE | base64 | tr -d '\n')
KUBECONFIG=$(pwd)/samples/rancher-gce/config/management-k3s.yaml
```

## Setup

### Management VM

Check authentifcation and enables services:

```bash
googlecloud_check_auth
googlecloud_enable_compute
```

Create the network:

```bash
googlecloud_create_vpc $GCLOUD_VPC
googlecloud_create_subnet $GCLOUD_SUBNET $GCLOUD_VPC $GCLOUD_REGION '10.0.0.0/24'
googlecloud_create_firewallrule "${GCLOUD_VPC}-allow-shell" $GCLOUD_VPC 'tcp:22' "${MY_IP}/32"
googlecloud_create_firewallrule "${GCLOUD_VPC}-allow-public" $GCLOUD_VPC 'tcp:80,tcp:443,icmp' '0.0.0.0/0'
googlecloud_create_firewallrule "${GCLOUD_VPC}-allow-internal" $GCLOUD_VPC 'All' '10.0.0.0/9'
googlecloud_create_firewallrule "${GCLOUD_VPC}-allow-healthcheck" $GCLOUD_VPC 'tcp' '35.191.0.0/16,130.211.0.0/22,209.85.152.0/22,209.85.204.0/22'
```

Create the VM:

```bash
gcloud compute addresses create $MANAGEMENT_STATICIP_NAME --region=$GCLOUD_REGION
googlecloud_create_vm $MANAGEMENT_VM_NAME $GCLOUD_PROJECT_ID $GCLOUD_ZONE n1-standard-4 ubuntu-2204-lts ubuntu-os-cloud $GCLOUD_SUBNET $MANAGEMENT_STATICIP_NAME
MANAGEMENT_VM_IP=$(googlecloud_get_vmip $MANAGEMENT_VM_NAME $GCLOUD_ZONE)
ssh-keyscan -H $MANAGEMENT_VM_IP >> ~/.ssh/known_hosts
gcloud compute disks resize $MANAGEMENT_VM_NAME --size=50 --zone=$GCLOUD_ZONE --quiet
gcloud compute ssh $MANAGEMENT_VM_NAME --zone=$GCLOUD_ZONE --command="sudo growpart /dev/sda 1"
gcloud compute ssh $MANAGEMENT_VM_NAME --zone=$GCLOUD_ZONE --command="sudo resize2fs /dev/sda1"
```

If needed, run the following commands:

- Open a shell in the VM

```bash
gcloud compute ssh $MANAGEMENT_VM_NAME --zone=$GCLOUD_ZONE
```

- Suspend the VM

```bash
gcloud compute instances suspend $MANAGEMENT_VM_NAME --zone=$GCLOUD_ZONE
```

- Resume the VM

```bash
gcloud compute instances resume $MANAGEMENT_VM_NAME --zone=$GCLOUD_ZONE
```

### Management cluster

Install required packages on the management VM:

```bash
ssh -i ~/.ssh/google_compute_engine $MANAGEMENT_VM_IP 'bash -s' < ./samples/rancher-gce/scripts/debian_packages.sh
```

Create the Kubernetes cluster on the management VM, with K3s distribution:

```bash
ssh -i ~/.ssh/google_compute_engine $MANAGEMENT_VM_IP "bash -s" < ./samples/rancher-gce/scripts/k3s.sh
```

### Rancher

Install Rancher:

```bash
RANCHER_DOMAIN="rancher.${MANAGEMENT_VM_IP}.sslip.io"
ssh -i ~/.ssh/google_compute_engine $MANAGEMENT_VM_IP "RANCHER_DOMAIN='${RANCHER_DOMAIN}' RANCHER_PASSWORD='${RANCHER_PASSWORD}' bash -s" < ./samples/rancher-gce/scripts/rancher.sh
update_env RANCHER_APITOKEN $(gcloud compute ssh $MANAGEMENT_VM_NAME --zone=$GCLOUD_ZONE --command="cat rancher_api.token")
update_env RANCHER_URL "https://${RANCHER_DOMAIN}"
```

Open Rancher in your browser and log in with this information:

```bash
echo "Rancher URL: ${RANCHER_URL}"
echo "Rancher username: admin"
echo "Rancher password: ${RANCHER_PASSWORD}"
```

Merge the cluster configuration with the local one:

```bash
# options 1 (need to open port 6443 in firewall)
scp -i ~/.ssh/google_compute_engine $MANAGEMENT_VM_IP:/etc/rancher/k3s/k3s.yaml samples/rancher-gce/config/management-k3s.yaml
sed -i "s|server: https://127.0.0.1:6443|server: https://$MANAGEMENT_VM_IP:6443|g" samples/rancher-gce/config/management-k3s.yaml

# option 2 (need Rancher)
rancher_get_kubeconfig $RANCHER_URL 'local' $RANCHER_APITOKEN samples/rancher-gce/config/management-k3s.yaml

# in all cases
chmod 600 samples/rancher-gce/config/management-k3s.yaml
KUBECONFIG=$(pwd)/samples/rancher-gce/config/management-k3s.yaml
```

Configure access to Google Cloud within Rancher from the browser:

- In Rancher, in Cluster Management, in Cloud Credentials, create new Google Cloud credentials
- Set Credential Name "googlecloud-myuser"
- Import the json key file

### Downstream GKE cluster -> OK

From the browser:

- In Rancher, in Cluster Management, create a new cluster Google GKE
- Set Google Project ID and click Authenticate
- Set name "gke-myname-myenv"
- In Node pools, can be renamed workload
- In Config, select the Zone
- In Networking, select the Network
- Click Save
- Wait few minutes for everything to be running smoothly

### Downstream GCE cluster with Node driver -> FAIL

From the browser:

- In Rancher, in Cluster Management, in Node Drivers, select Google GCE, and click Activate
- In Rancher, in Cluster Management, create a new cluster Google GCE
- Set a name "rke2-bthomas-demo"
- Rename the machine pool
- Click Save

The rke2-bthomas-demo-workload-jl8pm-vzcs9-machine-provision-7wmh5 pod is in error:

> error loading host rke2-bthomas-demo-workload-jl8pm-vzcs9: Docker machine "rke2-bthomas-demo-workload-jl8pm-vzcs9" does not exist. Use "docker-machine ls" to list machines. Use "docker-machine create" to add a new one.

### Kubernetes Cluster API (CAPI)

Install Rancher Turtles:

```bash
ssh -i ~/.ssh/google_compute_engine $MANAGEMENT_VM_IP "bash -s" < ./samples/rancher-gce/scripts/rancher_turtles.sh
```

References:

- Kubernetes Cluster API (CAPI) [quick start](https://cluster-api.sigs.k8s.io/user/quick-start.html)
- CAPI provider for RKE2 [rancher/cluster-api-provider-rke2](https://github.com/rancher/cluster-api-provider-rke2)
- Rancher Turtles [docs](https://turtles.docs.rancher.com/turtles/v0.15/en/index.html), [releases](https://github.com/rancher/turtles/releases), [e2e/cluster-templates](https://github.com/rancher/turtles/tree/main/test/e2e/data/cluster-templates)
- Examples [ashawka/capi-demo](https://github.com/ashawka/capi-demo)

### Downstream GKE cluster with Cluster API and Rancher Turtles

Initialize Google Cloud CAPI Provider (ref. [The Cluster API Book > Quick Start](https://cluster-api.sigs.k8s.io/user/quick-start)):

```bash
export GCP_B64ENCODED_CREDENTIALS=$(cat $GCLOUD_SERVICEACCOUNT_KEYSFILE | base64 | tr -d '\n')

# important to be done before (see https://cluster-api-gcp.sigs.k8s.io/managed/enabling, https://github.com/kubernetes-sigs/cluster-api-provider-gcp/discussions/925),
# otherwise, if init of the provider already done delete the infrastructure + manual deletion of namespace and CRDs (`clusterctl delete --infrastructure `gcp`)
export EXP_CAPG_GKE=true

clusterctl init --infrastructure gcp
```

Create manifest file (ref. [Kubernetes Cluster API Provider GCP > Provisioning a GKE cluster](https://cluster-api-gcp.sigs.k8s.io/managed/provision)):

```bash
export GCP_PROJECT=$GCLOUD_PROJECT_ID
export GCP_REGION=$GCLOUD_REGION
export GCP_NETWORK_NAME=$GCLOUD_VPC
export WORKER_MACHINE_COUNT=1

clusterctl generate cluster gke-capi-bthomas-demo --flavor gke -i gcp  > capi-gke-quickstart.yaml
```

References:

- CAPI provider for Google Cloud [code](https://github.com/kubernetes-sigs/cluster-api-provider-gcp), [book](https://cluster-api-gcp.sigs.k8s.io/),
[test/e2e/data](https://github.com/kubernetes-sigs/cluster-api-provider-gcp/tree/main/test/e2e/data/infrastructure-gcp)

Known issues:

- [PR #1364](https://github.com/kubernetes-sigs/cluster-api-provider-gcp/pull/1364)

### Downstream RKE2 cluster on GCE with Cluster API and Rancher Turtles

Initialize RKE2 Provider (ref. [Kubernetes Cluster API Provider RKE2 > Getting Started](https://caprke2.docs.rancher.com/01_user/01_getting-started.html)):

```bash
clusterctl init --bootstrap rke2 --control-plane rke2 --infrastructure gcp
```

```bash
export GCP_REGION=$GCLOUD_REGION
export GCP_PROJECT=$GCLOUD_PROJECT_ID
export KUBERNETES_VERSION=1.23.3 # TODO
export IMAGE_ID=projects/$GCP_PROJECT/global/images/<built image> # TODO
export GCP_CONTROL_PLANE_MACHINE_TYPE=n1-standard-2
export GCP_NODE_MACHINE_TYPE=n1-standard-2
export GCP_NETWORK_NAME=$GCLOUD_VPC # TODO: VPC or SUBNET?
export CLUSTER_NAME=rke2-demo # TODO
```

```bash
clusterctl generate cluster capi-quickstart \
  --kubernetes-version v1.32.0 \
  --control-plane-machine-count=3 \
  --worker-machine-count=3 \
  > capi-quickstart.yaml

clusterctl generate cluster --from https://github.com/rancher/cluster-api-provider-rke2/blob/main/examples/aws/cluster-template.yaml -n example-aws rke2-aws > aws-rke2-clusterctl.yaml
```

```bash
kubectl apply -f capi-quickstart.yaml
kubectl get cluster
clusterctl describe cluster capi-quickstart
clusterctl get kubeconfig capi-quickstart > capi-quickstart.kubeconfig
```

```bash
kubectl delete cluster capi-quickstart
```

References:

- CAPI provider for RKE2 [code](https://github.com/rancher/cluster-api-provider-rke2), [docs](https://caprke2.docs.rancher.com/00_introduction.html)
