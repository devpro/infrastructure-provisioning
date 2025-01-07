# Rancher on Google Cloud Compute Engine (VM)

In this scenario, we'll see how we can use Rancher to manage Kubernetes clusters in Google Cloud.

## Requirements

### Google Cloud SDK

If not already installed, download and install the [SDK](https://cloud.google.com/sdk/) on your machine:

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

From the browser:

- Go to [Service Accounts](https://console.cloud.google.com/projectselector/iam-admin/serviceaccounts)
- Switch to your Google Cloud account (may be different from your Google Workspace account)
- Select the project
- Create a service account if it does not already exist
- Create a key and download the json file

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
GCLOUD_SUBNET='subnet-xxx-demo'
GCLOUD_VPC='vpc-xxx-demo'
GCLOUD_ZONE='europe-west1-b'
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
googlecloud_create_firewallrule "${GCLOUD_VPC}-allow-internal" $GCLOUD_VPC 'All' '10.128.0.0/9' # default internal IP range for VMs in the VPC
googlecloud_create_firewallrule "${GCLOUD_VPC}-allow-healthcheck" $GCLOUD_VPC 'tcp' '35.191.0.0/16,130.211.0.0/22,209.85.152.0/22,209.85.204.0/22'
```

Create the VM:

```bash
gcloud compute addresses create $MANAGEMENT_STATICIP_NAME --region=$GCLOUD_REGION
googlecloud_create_vm $MANAGEMENT_VM_NAME $GCLOUD_PROJECT_ID $GCLOUD_ZONE n1-standard-4 ubuntu-2204-lts ubuntu-os-cloud $GCLOUD_SUBNET $MANAGEMENT_STATICIP_NAME
MANAGEMENT_VM_IP=$(googlecloud_get_vmip $MANAGEMENT_VM_NAME $GCLOUD_ZONE)
ssh-keyscan -H $MANAGEMENT_VM_IP >> ~/.ssh/known_hosts
#googlecloud_execute_vmcommand $MANAGEMENT_VM_NAME $GCLOUD_ZONE "ls -alrt"
```

If needed, run the following commands.

- Open a shell in the VM:

```bash
gcloud compute ssh $MANAGEMENT_VM_NAME --zone=$GCLOUD_ZONE
```

- Suspend the VM:

```bash
gcloud compute instances suspend $MANAGEMENT_VM_NAME --zone=$GCLOUD_ZONE
```

- Resume the VM:

```bash
gcloud compute instances resume $MANAGEMENT_VM_NAME --zone=$GCLOUD_ZONE
```

### Management cluster

Install required packages on the management VM:

```bash
ssh -i ~/.ssh/google_compute_engine $MANAGEMENT_VM_IP 'bash -s' < ./samples/rancher-gce/debian_packages.sh
```

Create the Kubernetes cluster on the management VM, with K3s distribution:

```bash
ssh -i ~/.ssh/google_compute_engine $MANAGEMENT_VM_IP "bash -s" < ./samples/rancher-gce/k3s.sh
```

### Rancher

Install Rancher:

```bash
ssh -i ~/.ssh/google_compute_engine $MANAGEMENT_VM_IP "RANCHER_DOMAIN='rancher.${MANAGEMENT_VM_IP}.sslip.io' RANCHER_PASSWORD='${RANCHER_PASSWORD}' bash -s" < ./samples/rancher-gce/rancher.sh
```

Open Rancher in your browser and log in with this information:

```bash
echo "Rancher URL: https://rancher.${MANAGEMENT_VM_IP}.sslip.io"
echo "Rancher username: admin"
echo "Rancher password: ${RANCHER_PASSWORD}"
```

Configure access to Google Cloud within Rancher from the browser:

- In Rancher, in Cluster Management, in Cloud Credentials, create new Google Cloud credentials
- Set Credential Name "googlecloud-myuser"
- Import the json key file

### Downstream GKE cluster (OK)

From the browser:

- In Rancher, in Cluster Management, create a new cluster Google GKE
- Set Google Project ID and click Authenticate
- Set name "gke-myname-myenv"
- In Node pools, can be renamed workload
- In Config, select the Zone
- In Networking, select the Network
- Click Save
- Wait few minutes for everything to be running smoothly

### Downstream GCE cluster with Node driver (FAIL)

From the browser:

- In Rancher, in Cluster Management, in Node Drivers, select Google GCE, and click Activate
- In Rancher, in Cluster Management, create a new cluster Google GCE
- Set a name "rke2-bthomas-demo"
- Rename the machine pool
- Click Save

The rke2-bthomas-demo-workload-jl8pm-vzcs9-machine-provision-7wmh5 pod is in error:

> error loading host rke2-bthomas-demo-workload-jl8pm-vzcs9: Docker machine "rke2-bthomas-demo-workload-jl8pm-vzcs9" does not exist. Use "docker-machine ls" to list machines. Use "docker-machine create" to add a new one.

### Downstream GCE cluster with Cluster API and Rancher Turtles

TODO

Rancher Turtles [documentation](https://turtles.docs.rancher.com/turtles/v0.15/en/index.html), [releases](https://github.com/rancher/turtles/releases), [](https://github.com/rancher/turtles/tree/main/test/e2e/data/cluster-templates)

https://github.com/ashawka/capi-demo
https://cluster-api.sigs.k8s.io/user/quick-start.html
https://github.com/kubernetes-sigs/cluster-api-provider-gcp
https://github.com/rancher/cluster-api-provider-rke2/

