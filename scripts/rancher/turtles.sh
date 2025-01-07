#!/bin/bash
# Collection of functions to use Rancher Turtles (Cluster API operator)

#######################################
# Install Rancher Turtles
# Arguments:
#   version
# Examples:
#   rancher_install_turtles 'v0.14.0'
#######################################
rancher_install_turtles() {
  local version=${1:-'v0.13.0'}

  helm repo add turtles https://rancher.github.io/turtles
  helm repo update

  helm install rancher-turtles turtles/rancher-turtles --version $version \
    -n rancher-turtles-system --create-namespace \
    --dependency-update \
    --wait --timeout 180s
}
