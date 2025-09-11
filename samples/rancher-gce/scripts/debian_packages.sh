#!/bin/bash

# installs kubectl (ref. https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl
kubectl version --client=true

# installs Helm (ref. https://helm.sh/docs/intro/install/)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version

# installs clusterctl (ref. https://cluster-api.sigs.k8s.io/user/quick-start)
curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.9.3/clusterctl-linux-amd64 -o clusterctl
sudo install -o root -g root -m 0755 clusterctl /usr/local/bin/clusterctl
rm clusterctl
clusterctl version

# installs jq
sudo apt-get install -y jq

# installs unzip
sudo apt-get install -y unzip
