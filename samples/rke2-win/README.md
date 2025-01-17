# RKE2 cluster with Windows worker nodes

## Setup

- Google Cloud

```bash
googlecloud_create_firewallrule "${GCLOUD_VPC}-allow-rdp" $GCLOUD_VPC 'tcp:3389' "${MY_IP}/32"
```

- Rancher

## RKE2 control plane

- Create Linux VM:

```bash
RKE2_LINUX_STATICIP_NAME='ip-bthomas-rke2lin'
gcloud compute addresses create $RKE2_LINUX_STATICIP_NAME --region=$GCLOUD_REGION
RKE2_LINUX_VM_NAME='vm-bthomas-rke2lin'
googlecloud_create_vm $RKE2_LINUX_VM_NAME $GCLOUD_PROJECT_ID $GCLOUD_ZONE n1-standard-4 ubuntu-2204-lts ubuntu-os-cloud $GCLOUD_SUBNET $RKE2_LINUX_STATICIP_NAME
RKE2_LINUX_VM_IP=$(googlecloud_get_vmip $RKE2_LINUX_VM_NAME $GCLOUD_ZONE)
ssh-keyscan -H $RKE2_LINUX_VM_IP >> ~/.ssh/known_hosts
gcloud compute disks resize $RKE2_LINUX_VM_NAME --size=50 --zone=$GCLOUD_ZONE --quiet
gcloud compute ssh $RKE2_LINUX_VM_NAME --zone=$GCLOUD_ZONE --command="sudo growpart /dev/sda 1"
gcloud compute ssh $RKE2_LINUX_VM_NAME --zone=$GCLOUD_ZONE --command="sudo resize2fs /dev/sda1"
```

- Create RKE2 cluster in Rancher (Custom cluster):

```bash
RKE2_CLUSTER_NAME='demo'
RKE2_K8S_VERSION='v1.31.3+rke2r1'
rancher_create_customcluster_nowait $RKE2_CLUSTER_NAME $RKE2_K8S_VERSION
RKE2_CLUSTER_ID=$(rancher_return_clusterid $RKE2_CLUSTER_NAME)
```

- Install RKE2 control plane on Linux VM:

```bash
RKE2_LINUX_REGISTERCOMMAND=$(rancher_return_clusterregistrationcommand $RKE2_CLUSTER_ID)
gcloud compute ssh $RKE2_LINUX_VM_NAME --zone=$GCLOUD_ZONE --command="${RKE2_LINUX_REGISTERCOMMAND} --etcd --controlplane --worker"
```

- Create Windows VM:

```bash
RKE2_WINDOWS_STATICIP_NAME='ip-bthomas-rke2win'
gcloud compute addresses create $RKE2_WINDOWS_STATICIP_NAME --region=$GCLOUD_REGION
RKE2_WINDOWS_VM_NAME='vm-bthomas-rke2win'
googlecloud_create_vm $RKE2_WINDOWS_VM_NAME $GCLOUD_PROJECT_ID $GCLOUD_ZONE n1-standard-4 windows-2022 windows-cloud $GCLOUD_SUBNET $RKE2_WINDOWS_STATICIP_NAME
RKE2_WINDOWS_VM_IP=$(googlecloud_get_vmip $RKE2_WINDOWS_VM_NAME $GCLOUD_ZONE)
```

- Install RKE2 worker on Windows VM:

```bash
RKE2_WINDOWS_REGISTERCOMMAND=$(rancher_return_clusterregistrationcommand $RKE2_CLUSTER_ID windows)
gcloud compute ssh $RKE2_WINDOWS_STATICIP_NAME --zone=$GCLOUD_ZONE --command="${RKE2_LINUX_REGISTERCOMMAND} --etcd --controlplane --worker"
```

- 
