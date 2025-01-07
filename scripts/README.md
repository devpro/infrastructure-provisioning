# Scripting

## Bash functions

### Google Cloud

Name                     | Source
-------------------------|-------------------------------------------
`googlecloud_check_auth` | [googlecloud/auth.sh](googlecloud/auth.sh)

### K3s

Name                  | Source
----------------------|-----------------------------------------------------
`k3s_copy_kubeconfig` | [k3s/cluster_lifecycle.sh](k3s/cluster_lifecycle.sh)
`k3s_create_cluster`  | [k3s/cluster_lifecycle.sh](k3s/cluster_lifecycle.sh)

### Kubernetes

Name                                  | Source
--------------------------------------|-----------------------------------------------------------------------------
`k8s_create_letsencryptclusterissuer` | [kubernetes/certificate_management.sh](kubernetes/certificate_management.sh)
`k8s_install_certmanager`             | [kubernetes/certificate_management.sh](kubernetes/certificate_management.sh)
`k8s_wait_fornodesandpods`            | [kubernetes/cluster_status.sh](kubernetes/cluster_status.sh)

### Linux

Name             | Source
-----------------|-------------------------------------
`linux_get_myip` | [linux/network.sh](linux/network.sh)

### Rancher

Name                                           | Source
-----------------------------------------------|-------------------------------------------------------------
`rancher_create_apikey`                        | [rancher/user_actions.sh](rancher/user_actions.sh)
`rancher_create_customcluster`                 | [rancher/cluster_actions.sh](rancher/cluster_actions.sh)
`rancher_first_login`                          | [rancher/manager_lifecycle.sh](rancher/manager_lifecycle.sh)
`rancher_get_clusterid`                        | [rancher/cluster_actions.sh](rancher/cluster_actions.sh)
`rancher_get_clusterregistrationcommand`       | [rancher/cluster_actions.sh](rancher/cluster_actions.sh)
`rancher_install_turtles`                      | [rancher/turtles.sh](rancher/turtles.sh)
`rancher_install_withcertmanagerclusterissuer` | [rancher/manager_lifecycle.sh](rancher/manager_lifecycle.sh)
`rancher_list_clusters`                        | [rancher/cluster_actions.sh](rancher/cluster_actions.sh)
`rancher_login_withpassword`                   | [rancher/user_actions.sh](rancher/user_actions.sh)
`rancher_update_password`                      | [rancher/user_actions.sh](rancher/user_actions.sh)
`rancher_update_serverurl`                     | [rancher/manager_settings.sh](rancher/manager_settings.sh)
`rancher_wait_capiready`                       | [rancher/manager_lifecycle.sh](rancher/manager_lifecycle.sh)

## Concrete examples

- [Rancher installation with downstream cluster](../samples/scripting/rancher_installation.sh)
