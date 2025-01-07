#!/bin/bash

# defines variables
SETUP_BRANCH=${SETUP_BRANCH:-'feature/init-scripts'}
K3S_VERSION=${K3S_VERSION:-'v1.30'}
CERTMANAGER_VERSION=${CERTMANAGER_VERSION:-'v1.16.2'}
INGRESS_CLASSNAME=${INGRESS_CLASSNAME:-'traefik'}
LETSENCRYPT_EMAIL_ADDRESS=${LETSENCRYPT_EMAIL_ADDRESS:-'john.wick@google.com'}

# downloads and sources shared scripts
curl -sfL -C - https://raw.githubusercontent.com/devpro/infrastructure-provisioning/${SETUP_BRANCH}/scripts/download.sh | GIT_REVISION=refs/heads/${SETUP_BRANCH} sh -s -- -o setup
. setup/scripts/index.sh

# creates administration Kubernetes cluster
k3s_create_cluster $K3S_VERSION
k3s_copy_kubeconfig
k8s_wait_fornodesandpods
k8s_install_certmanager $CERTMANAGER_VERSION
k8s_create_letsencryptclusterissuer $INGRESS_CLASSNAME $LETSENCRYPT_EMAIL_ADDRESS
