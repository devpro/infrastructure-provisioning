# Two-Node High Availability to Kubernetes with K3s and NATS

🌐 [The next gen platform for the edge: SUSE and Synadia Bring Two-Node High Availability to Kubernetes](https://www.suse.com/c/the-next-gen-platform-for-the-edge-suse-and-synadia-bring-two-node-high-availability-to-kubernetes/) - March 11, 2024

## Installation

### Pre-requisites

Have two separate machines (virtual or physical) with known IP addresses.

They must meet the [k3s networking requirements](https://docs.k3s.io/installation/requirements#networking) and allow access to port 4222 for NATS traffic. Easiest solution (for demo purposes) is to disable the firewall:

```bash
sudo ufw status
```

Make sure common packages required by k3s are installed:

```bash
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
```

You can validate the setup with a basic k3s scenario:

```bash
# installs K3s
curl -sfL https://get.k3s.io | sh -

# checks K3s seervice is running
systemctl status k3s

# looks at what is running in the cluster
sudo kubectl get all -n kube-system

# uninstalls K3s
/usr/local/bin/k3s-uninstall.sh
```

### Setup

TODO

### Deployment

TODO

## Usage

### Start

Once the files are deployed on their respective hosts, use `sudo ./start.sh` to start the k3s instance on each host.

Wait for the the logs on the first node to display:

```log
(DEBUG) FSM STATES:
        active state: leader
        transitioned: false
        isLeaderRX: false
        hasBeenFollower: false
        remoteLeader: false
        remoteLeaderRX: false
        apiStart: true
        network: true
        apiProbe: true
        ossProbe: true
        neigh: true
```

Wait for the the logs on the second node to display:

```log
(DEBUG) FSM STATES:
        active state: follower
        transitioned: false
        isLeaderRX: false
        hasBeenFollower: true
        remoteLeader: true
        remoteLeaderRX: false
        apiStart: true
        network: true
        apiProbe: true
        ossProbe: true
        neigh: true
```

Check everything is ok

```bash
./k3s kubectl get node
```

### Client configuration

From one of the node, merge content of `/etc/rancher/k3s/k3s.yaml` in your local kubeconfig, replace cluster name default to a more explicit one and replace 127.0.0.1 to the first node IP.

Check you can connect and interact with the remote cluster:

```bash
kubectl get nodes
helm list -A
```

### ngrok Ingress Controller

We can use ngrok to ease the exposition of our apps thanks to [ngrok Kubernetes Ingress Controller](https://github.com/ngrok/kubernetes-ingress-controller).

```bash
# adds ngrok chart repo
helm repo add ngrok https://ngrok.github.io/kubernetes-ingress-controller

# creates ngrok namespace
kubectl create ns ngrok-ingress-controller

# creates a secret with ngrok authentification (grab Authentication Token and API key from https://dashboard.ngrok.com/)
kubectl create secret generic --namespace ngrok-ingress-controller ngrok-credentials \
--from-literal=AUTHTOKEN=[AUTHTOKEN] \
--from-literal=API_KEY=[APIKEY]

# installs ngrok Ingress Controller
helm upgrade --install ngrok-ingress-controller ngrok/kubernetes-ingress-controller \
--namespace ngrok-ingress-controller \
--create-namespace \
--set credentials.secret.name=ngrok-credentials
```

### Cow demo application

```bash
# adds devpro chart repo
helm repo add devpro https://devpro.github.io/helm-charts

# adds the web app without ingress
helm upgrade --install cow-demo devpro/cow-demo --create-namespace --namespace demo --set cow.color=green --set replicaCount=6

# makes sure the application runs fine (it will be accessible on http://localhost:8080)
kubectl port-forward service/cow-demo-svc 8080:80 -n demo

# updates the web app with ingress
helm upgrade --install cow-demo devpro/cow-demo --create-namespace --namespace demo \
--set ingress.enabled=true \
--set ingress.className=ngrok \
--set host=cow-demo.kubecon24.ngrok.app \
--set 'ingress.annotations.cert-manager\.io/cluster-issuer=selfsigned-cluster-issuer' \
--set cow.color=green --set replicaCount=6
```

Open [cow-demo.kubecon24.ngrok.app](https://cow-demo.kubecon24.ngrok.app)

### Game 2048 application

```bash
# creates the web app with ingress
helm upgrade --install game-2048 devpro/game-2048 --create-namespace --namespace demo \
--set ingress.enabled=true \
--set ingress.className=ngrok \
--set ingress.host=game-2048.kubecon24.ngrok.app \
--set 'ingress.annotations.cert-manager\.io/cluster-issuer=selfsigned-cluster-issuer'
```

Open [game-2048.kubecon24.ngrok.app](https://game-2048.kubecon24.ngrok.app)

### Install Akri

```bash
# adds akri chart repo
helm repo add akri-helm-charts https://project-akri.github.io/akri/

# installs akri
helm install akri akri-helm-charts/akri --set kubernetesDistro=k3s
```
