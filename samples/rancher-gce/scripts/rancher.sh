#!/bin/bash

# ============================================
# Script Name: rancher.sh
# Description: This script installs Rancher in an existing Kubernetes cluster.
#
# Required Environment Variables:
#   - RANCHER_DOMAIN: The domain for Rancher web application.
#   - RANCHER_PASSWORD: The password for the Rancher admin user.
#
# Optional Environment Variables:
#   - SETUP_BRANCH: Git branch name for the setup scripts repo.
#   - INGRESS_CLASSNAME: Ingress class name.
#   - CERTMANAGER_ISSUER: Cerificate issuer defined in cert-manager.
#   - RANCHER_REPOSITORY: Repository to install Rancher.
#   - RANCHER_VERSION: Version of Rancher app.
#   - RANCHER_REPLICAS: Number of replicas for Rancher app.
#
# Usage:
#   Export the required environment variables before running the script:
#     export RANCHER_DOMAIN="rancher.example.com"
#     export RANCHER_PASSWORD="123456"
#     ./rancher.sh
# ============================================

# defines variables
SETUP_BRANCH=${SETUP_BRANCH:-'feature/init-scripts'}
INGRESS_CLASSNAME=${INGRESS_CLASSNAME:-'traefik'}
CERTMANAGER_ISSUER=${CERTMANAGER_ISSUER:-'letsencrypt-prod'}
RANCHER_REPOSITORY=${RANCHER_REPOSITORY:-'latest'}
RANCHER_VERSION=${RANCHER_VERSION:-'2.10.1'}
RANCHER_REPLICAS=${RANCHER_REPLICAS:-'1'}
RANCHER_URL="https://${RANCHER_DOMAIN}"

# downloads and sources shared scripts
curl -sfL -C - https://raw.githubusercontent.com/devpro/infrastructure-provisioning/${SETUP_BRANCH}/scripts/download.sh | GIT_REVISION=refs/heads/${SETUP_BRANCH} sh -s -- -o setup
. setup/scripts/index.sh

# installs & initializes Rancher
rancher_install_withcertmanagerclusterissuer $RANCHER_REPOSITORY $RANCHER_VERSION $RANCHER_REPLICAS $RANCHER_DOMAIN $CERTMANAGER_ISSUER
rancher_first_login $RANCHER_URL $RANCHER_PASSWORD
rancher_create_apikey $RANCHER_URL $LOGIN_TOKEN 'Automation API Key'
echo $API_TOKEN > rancher_api.token
rancher_wait_capiready
