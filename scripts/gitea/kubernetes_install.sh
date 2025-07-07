#!/bin/bash
# Collection of functions to run Gitea in a Kubernetes cluster (https://docs.gitea.com/installation/install-on-kubernetes, https://gitea.com/gitea/helm-gitea)

#######################################
# Installs Gitea in Kubernetes cluster as a single pod with an Ingress and a certificate (https://gitea.com/gitea/helm-gitea#single-pod-configurations)
# Arguments:
#   Admin user password
#   Ingress class name (nginx, traefik)
#   Cluster issuer to be used by cert-manager
#   Host domain
# Examples:
#   gitea_kubernetes_install_singlepod SuperAdmin123 traefik letsencrypt-prod gitea.some.domain.net
#######################################
gitea_kubernetes_install_singlepod() {
  local adminPassword=$1
  local ingressClassName=$2
  local certificateClusterIssuer=$3
  local hostDomain=$4

  echo "Installing Gitea in the Kubernetes cluster"

  helm repo add gitea-charts https://dl.gitea.com/charts/
  helm repo update

  helm upgrade --install gitea gitea-charts/gitea --namespace gitea --create-namespace \
    --set persistence.enabled=false \
    --set postgresql.enabled=false \
    --set postgresql-ha.enabled=false \
    --set valkey.enabled=false \
    --set valkey-cluster.enabled=false \
    --set gitea.admin.username=admin \
    --set gitea.admin.password=$adminPassword \
    --set gitea.config.database.DB_TYPE=sqlite3 \
    --set gitea.config.session.PROVIDER=memory \
    --set gitea.config.cache.ADAPTER=memory \
    --set gitea.config.queue.TYPE=level \
    --set ingress.enabled=true \
    --set ingress.className=$ingressClassName \
    --set ingress.annotations.'cert-manager\.io/cluster-issuer'=$certificateClusterIssuer \
    --set ingress.hosts[0].host=$hostDomain \
    --set ingress.tls[0].secretName=gitea-tls \
    --set ingress.tls[0].hosts[0]=$hostDomain

  kubectl wait pods -n gitea -l app=gitea --for condition=Ready --timeout=180s
  while ! kubectl get secret gitea-tls --namespace gitea 2>/dev/null; do sleep 1; done
}
