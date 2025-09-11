#!/bin/bash
# Collection of functions to manage networks in Google Cloud

#######################################
# Create VPC
# Examples:
#   googlecloud_create_vpc my-vpc-network
#######################################
googlecloud_create_vpc() {
  local name=$1

  gcloud compute networks create $name --subnet-mode=custom
}

#######################################
# Delete VPC
# Examples:
#   googlecloud_delete_vpc my-subnet
#######################################
googlecloud_delete_vpc() {
  local name=$1

  gcloud compute networks delete $name
}

#######################################
# Create Subnet
# Examples:
#   googlecloud_create_subnet my-subnet my-vpc-network us-central1 10.0.0.0/24
#######################################
googlecloud_create_subnet() {
  local name=$1
  local vpc=$2
  local region=$3
  local range=$4

  gcloud compute networks subnets create $name --network=$vpc --region=$region --range=$range
}
