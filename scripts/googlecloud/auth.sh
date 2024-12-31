#!/bin/bash
# Collection of functions to manage Google Cloud authentication

#######################################
# Check user authentication
# Examples:
#   googlecloud_check_auth
#######################################
googlecloud_check_auth() {
  if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" >/dev/null; then
    echo "You are not authenticated. Please run 'gcloud auth login' before running this script."
    exit 1
  fi
}
