# Rancher on Google Cloud Compute Engine (VM)

## Requirements

### Google Cloud SDK

If not already installed, download and install the [Google Cloud SDK](https://cloud.google.com/sdk/).

Check the SDK is installed:

```bash
gcloud version
```

### Google Cloud account

If your organization has a landing zone, make sure to log in through it to the right user (your Google account may not be the one to be used to Google Cloud).

Authentify:

```bash
gcloud auth login
```

## Installation

Source the files:

```bash
. ./scripts/index.sh
```

Check authentifcation and enables services:

```bash
googlecloud_check_auth
googlecloud_enable_compute
```

Define the variables:

```bash
GCLOUD_PROJECT_ID='presales-emea-119943' # your-project-id
GCLOUD_REGION='europe-west1'
GCLOUD_ZONE='europe-west1-b'
GCLOUD_SUBNET='subnet-bthomas-demo'
GCLOUD_VPC='vpc-bthomas-demo'
MANAGEMENT_VM_NAME='vm-management'
```

Get dynamic variables:

```bash
MY_IP=$(linux_get_myip)
```

Create the network:

```bash
googlecloud_create_vpc $GCLOUD_VPC
googlecloud_create_subnet $GCLOUD_SUBNET $GCLOUD_VPC $GCLOUD_REGION '10.0.0.0/24'
```

Create the VM:

```bash
googlecloud_create_vm $MANAGEMENT_VM_NAME $GCLOUD_PROJECT_ID $GCLOUD_ZONE n1-standard-8 ubuntu-2204-lts ubuntu-os-cloud $GCLOUD_SUBNET
MANAGEMENT_VM_IP=$(googlecloud_get_vmip $MANAGEMENT_VM_NAME $GCLOUD_ZONE)
googlecloud_create_firewallrule "${GCLOUD_VPC}-admin" $GCLOUD_VPC "tcp:22,tcp:80,tcp:443" "${MY_IP}/32"
ssh-keyscan -H $MANAGEMENT_VM_IP >> ~/.ssh/known_hosts
#googlecloud_execute_vmcommand $MANAGEMENT_VM_NAME $GCLOUD_ZONE "ls -alrt"
```

Install Rancher:

```bash
ssh -i ~/.ssh/google_compute_engine $MANAGEMENT_VM_IP 'bash -s' < ./samples/rancher-gce/debian-packages.sh
ssh -i ~/.ssh/google_compute_engine $MANAGEMENT_VM_IP "RANCHER_DOMAIN='rancher.${MANAGEMENT_VM_IP}.sslip.io' bash -s" < ./samples/rancher-gce/rancher.sh
```
