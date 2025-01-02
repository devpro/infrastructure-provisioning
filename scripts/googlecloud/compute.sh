#!/bin/bash
# Collection of functions to use Google Cloud Compute Engine (Virtual Machines)

#######################################
# Enables compute service
# Examples:
#   googlecloud_enable_compute
#######################################
googlecloud_enable_compute() {
  gcloud services enable compute.googleapis.com
}

#######################################
# Lists images
# Examples:
#   googlecloud_list_images
#######################################
googlecloud_list_images() {
  gcloud compute images list
}

#######################################
# Create a VM
# Arguments:
#   Name for the new VM
#   Project ID
#   Zone
#   Machine type (VM specs)
#   Image family (OS)
#   Image project
#   Subnet
# Examples:
#   googlecloud_create_vm my-vm my-project europe-west1-b n1-standard-8 ubuntu-2204-lts ubuntu-os-cloud my-vpc
#######################################
googlecloud_create_vm() {
  local name=$1
  local projectId=$2
  local zone=$3
  local machinType=$4
  local imageFamily=$5
  local imageProject=$6
  local subnet=$7

  echo 'Creating VM (Google Cloud Compute Engine)...'

  gcloud compute instances create "${name}" \
    --project="${projectId}" \
    --zone="${zone}" \
    --machine-type="${machinType}" \
    --image-family="${imageFamily}" \
    --image-project="${imageProject}" \
    --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=${subnet}

  echo "VM ${name} created successfully"
}

#######################################
# Get the external IP of a VM
# Arguments:
#   Name for the new VM
#   Zone
# Returns:
#   Public IP address
# Examples:
#   googlecloud_get_vmip my-vm europe-west1-b
#######################################
googlecloud_get_vmip() {
  local name=$1
  local zone=$2

  echo $(gcloud compute instances describe "${name}" \
    --zone="${zone}" \
    --format="get(networkInterfaces[0].accessConfigs[0].natIP)")
}

# Instances on this network will not be reachable until firewall rules are created.
# As an example, you can allow all internal traffic between instances as well as SSH, RDP, and ICMP by running:

# $ gcloud compute firewall-rules create <FIREWALL_NAME> --network my-vpc-network --allow tcp,udp,icmp --source-ranges <IP_RANGE>
# $ gcloud compute firewall-rules create <FIREWALL_NAME> --network my-vpc-network --allow tcp:22,tcp:3389,icmp

#######################################
# Create firewall rule to give access to a VM
# Arguments:
#   Rule name
#   VPC name
#   Region
# Examples:
#   googlecloud_create_firewallrule my-rule my-vpc-network "tcp:22,tcp:80,tcp:443" x.x.x.x/32
#######################################
googlecloud_create_firewallrule() {
  local name=$1
  local vpc=$2
  local allow=$3
  local iprange=$4

  gcloud compute firewall-rules create $name \
    --network $vpc \
    --allow $allow \
    --source-ranges $iprange \
    --quiet

  if [ $? -eq 0 ]; then
    echo "Firewall rule updated to allow traffic from ${iprange}"
  else
    echo "Failed to update the firewall rule."
  fi
}

# TODO: create googlecloud_create_firewallrule function (`gcloud compute firewall-rules delete $name`)

#######################################
# Run a command on a VM through SSH
# Arguments:
#   VM name
#   Zone
# Examples:
#   googlecloud_execute_vmcommand my-vm europe-west1-b ls
#######################################
googlecloud_execute_vmcommand() {
  local name=$1
  local zone=$2
  local command=$3

  gcloud compute ssh $name --zone=$zone --command="${command}"
}
