#!/bin/bash

update_env() {
  local key=$1
  local value=$2
  local env_file=${3:-'.env'}

  # ensures the file exists
  if [ ! -f "$env_file" ]; then
      touch "$env_file"
  fi

  # replaces the line if the key exists; otherwise, add it
  if grep -q "^$key=" "$env_file"; then
      sed -i "s|^$key=.*|$key=$value|" "$env_file"
      echo "Updated $key in $env_file."
  else
      echo "$key=$value" >> "$env_file"
      echo "Added $key to $env_file."
  fi

  export $key=$value
}
