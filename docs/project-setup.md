# Project setup

## Example

Create a file `rancher_gce.sh` in the workspace folder with the content:

```sh
#!/bin/bash
cd devpro/infrastructure-provisioning
. ./scripts/index.sh
googlecloud_check_auth
set -a
source ./samples/rancher-gce/.env
source ./samples/rke2-win/.env
MY_IP=$(linux_get_myip)
GCP_B64ENCODED_CREDENTIALS=$(cat $GCLOUD_SERVICEACCOUNT_KEYSFILE | base64 | tr -d '\n')
MANAGEMENT_VM_IP=$(googlecloud_get_vmip $MANAGEMENT_VM_NAME $GCLOUD_ZONE)
set +a
clear
```
