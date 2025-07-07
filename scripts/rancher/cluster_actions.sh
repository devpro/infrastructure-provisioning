#!/bin/bash
# Collection of functions to manage clusters from Rancher

#######################################
# List clusters managed by Rancher
# Examples:
#   rancher_list_clusters
#######################################
rancher_list_clusters() {
  echo 'Listing clusters registered in Rancher...'
  kubectl get clusters.provisioning.cattle.io --all-namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'
}

#######################################
# Create downstream custom cluster in Rancher (don't wait and retrieve name)
# Globals:
#   CLUSTER_ID
# Arguments:
#   name
#   version (Kubernetes)
# Examples:
#   rancher_create_customcluster_nowait demo 'v1.27.16+rke2r1'
#######################################
rancher_create_customcluster_nowait() {
  local name=$1
  local version=$2

  echo 'Creating downstream cluster in Rancher...'
  cat <<EOF | kubectl apply -f -
apiVersion: provisioning.cattle.io/v1
kind: Cluster
metadata:
  name: "$name"
  namespace: fleet-default
spec:
  kubernetesVersion: "$version"
  localClusterAuthEndpoint: {}
  rkeConfig:
    chartValues:
      rke2-calico: {}
    dataDirectories: {}
    etcd:
      snapshotRetention: 5
      snapshotScheduleCron: 0 */5 * * *
    machineGlobalConfig:
      cni: calico
      disable-kube-proxy: false
      etcd-expose-metrics: false
    machinePoolDefaults: {}
    machineSelectorConfig:
      - config:
          protect-kernel-defaults: false
    registries: {}
    upgradeStrategy:
      controlPlaneConcurrency: '1'
      controlPlaneDrainOptions:
        deleteEmptyDirData: true
        disableEviction: false
        enabled: false
        force: false
        gracePeriod: -1
        ignoreDaemonSets: true
        ignoreErrors: false
        postDrainHooks: null
        preDrainHooks: null
        skipWaitForDeleteTimeoutSeconds: 0
        timeout: 120
      workerConcurrency: '1'
      workerDrainOptions:
        deleteEmptyDirData: true
        disableEviction: false
        enabled: false
        force: false
        gracePeriod: -1
        ignoreDaemonSets: true
        ignoreErrors: false
        postDrainHooks: null
        preDrainHooks: null
        skipWaitForDeleteTimeoutSeconds: 0
        timeout: 120
EOF
}

#######################################
# Create downstream custom cluster in Rancher
# Globals:
#   CLUSTER_ID
# Arguments:
#   name
#   version (Kubernetes)
# Examples:
#   rancher_create_customcluster demo 'v1.27.16+rke2r1'
#######################################
rancher_create_customcluster() {
  local name=$1
  local version=$2

  rancher_create_customcluster_nowait $name $version
  sleep 10
}

#######################################
# Return cluster ID from its name
# Arguments:
#   name
# Examples:
#   CLUSTER_ID=$(rancher_return_clusterid demo)
#######################################
rancher_return_clusterid() {
  local name=$1

  kubectl get cluster.provisioning.cattle.io -n fleet-default -o=jsonpath="{range .items[?(@.metadata.name==\"${name}\")]}{.status.clusterName}{end}"
}

#######################################
# Return cluster registration command line from Rancher
# Arguments:
#   cluster ID
#   operating system family (linux, windows) - optional (linux by default)
# Examples:
#   CLUSTER_REGISTRATION_COMMAND=$(rancher_return_clusterregistrationcommand 42)
#######################################
rancher_return_clusterregistrationcommand() {
  local id=$1
  local osfamily=${2:-'linux'}

  if [ "$osfamily" == 'linux' ]; then
    kubectl get clusterregistrationtoken.management.cattle.io -n $id -o=jsonpath='{.items[*].status.nodeCommand}'
  else
    kubectl get clusterregistrationtoken.management.cattle.io default-token -n $id -o=jsonpath='{.status.windowsNodeCommand}'
  fi
}
