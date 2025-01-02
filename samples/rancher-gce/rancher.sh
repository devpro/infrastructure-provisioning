#!/bin/bash

# defines variables
SETUP_BRANCH='feature/init-scripts'
K3S_VERSION='v1.30'
CERTMANAGER_VERSION='v1.13.0'
INGRESS_CLASSNAME='traefik'
LETSENCRYPT_EMAIL_ADDRESS='john.wick@google.com'
RANCHER_REPOSITORY='latest'
RANCHER_VERSION='2.9.1'
RANCHER_REPLICAS='1'

# downloads and sources shared scripts
curl -sfL -C - https://raw.githubusercontent.com/devpro/infrastructure-provisioning/${SETUP_BRANCH}/scripts/download.sh | GIT_REVISION=refs/heads/${SETUP_BRANCH} sh -s -- -o setup
. setup/scripts/index.sh

# creates administration Kubernetes cluster
k3s_create_cluster $K3S_VERSION
k3s_copy_kubeconfig
k8s_wait_fornodesandpods
k8s_install_certmanager $CERTMANAGER_VERSION
k8s_create_letsencryptclusterissuer $INGRESS_CLASSNAME $LETSENCRYPT_EMAIL_ADDRESS

# installs & initializes Rancher
rancher_install_withcertmanagerclusterissuer $RANCHER_REPOSITORY $RANCHER_VERSION $RANCHER_REPLICAS $RANCHER_DOMAIN letsencrypt-prod
RANCHER_URL="https://${RANCHER_DOMAIN}"
rancher_first_login $RANCHER_URL $RANCHER_PASSWORD
rancher_create_apikey $RANCHER_URL $LOGIN_TOKEN 'Automation API Key'
rancher_wait_capiready
