#!/bin/bash

# ============================================
# Script Name: rancher_turtles.sh
# Description: This script installs Rancher Turtles in an existing Kubernetes cluster with Rancher already running.
#
# Optional Environment Variables:
#   - SETUP_BRANCH: Git branch name for the setup scripts repo.
#   - RANCHERTURTLES_VERSION: Version of Rancher Turtles.
#
# Usage:
#   Export the required environment variables before running the script:
#     ./rancher.sh
# ============================================

# defines variables
SETUP_BRANCH=${SETUP_BRANCH:-'feature/init-scripts'}
RANCHERTURTLES_VERSION=${RANCHERTURTLES_VERSION:-'v0.15.0'}

# downloads and sources shared scripts
curl -sfL -C - https://raw.githubusercontent.com/devpro/infrastructure-provisioning/${SETUP_BRANCH}/scripts/download.sh | GIT_REVISION=refs/heads/${SETUP_BRANCH} sh -s -- -o setup
. setup/scripts/index.sh

# installs Rancher Turtles
rancher_install_turtles $RANCHERTURTLES_VERSION
