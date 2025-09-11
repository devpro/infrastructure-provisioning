#!/bin/bash
# Collection of network functions on Linux

#######################################
# Get my external IP
# Returns:
#   Public IP address
# Examples:
#   linux_get_myip
#######################################
linux_get_myip() {
  local myip=$(curl -s https://ipinfo.io/ip)

  if [ -z "$myip" ]; then
    echo "Failed to retrieve public IP address."
    exit 1
  fi

  echo $myip
}
