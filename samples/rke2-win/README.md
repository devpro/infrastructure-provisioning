# RKE2 cluster with Windows worker nodes

## Setup

- Workstation firewall (ports: 22, 3389, 5986)

- Google Cloud

```bash
googlecloud_create_firewallrule "${GCLOUD_VPC}-allow-rdp" $GCLOUD_VPC 'tcp:3389' "${MY_IP}/32"
googlecloud_create_firewallrule "${GCLOUD_VPC}-allow-winrm" $GCLOUD_VPC 'tcp:5986' "${MY_IP}/32"
```

- Rancher

## RKE2 control plane

- Create Linux VM:

```bash
RKE2_LINUX_STATICIP_NAME='ip-bthomas-rke2lin'
gcloud compute addresses create $RKE2_LINUX_STATICIP_NAME --region=$GCLOUD_REGION
RKE2_LINUX_VM_NAME='vm-bthomas-rke2lin'
googlecloud_create_vm $RKE2_LINUX_VM_NAME $GCLOUD_PROJECT_ID $GCLOUD_ZONE n1-standard-4 ubuntu-2204-lts ubuntu-os-cloud $GCLOUD_SUBNET $RKE2_LINUX_STATICIP_NAME
RKE2_LINUX_VM_IP=$(googlecloud_get_vmip $RKE2_LINUX_VM_NAME $GCLOUD_ZONE)
ssh-keyscan -H $RKE2_LINUX_VM_IP >> ~/.ssh/known_hosts
gcloud compute disks resize $RKE2_LINUX_VM_NAME --size=50 --zone=$GCLOUD_ZONE --quiet
gcloud compute ssh $RKE2_LINUX_VM_NAME --zone=$GCLOUD_ZONE --command="sudo growpart /dev/sda 1"
gcloud compute ssh $RKE2_LINUX_VM_NAME --zone=$GCLOUD_ZONE --command="sudo resize2fs /dev/sda1"
```

- Create RKE2 cluster in Rancher (Custom cluster):

```bash
RKE2_CLUSTER_NAME='demo'
RKE2_K8S_VERSION='v1.31.3+rke2r1'
rancher_create_customcluster_nowait $RKE2_CLUSTER_NAME $RKE2_K8S_VERSION
RKE2_CLUSTER_ID=$(rancher_return_clusterid $RKE2_CLUSTER_NAME)
```

- Install RKE2 control plane on Linux VM:

```bash
RKE2_LINUX_REGISTERCOMMAND=$(rancher_return_clusterregistrationcommand $RKE2_CLUSTER_ID)
gcloud compute ssh $RKE2_LINUX_VM_NAME --zone=$GCLOUD_ZONE --command="${RKE2_LINUX_REGISTERCOMMAND} --etcd --controlplane --worker"
# TODO wait for the cluster to be ready
RKE2_CLUSTER_ID=$(rancher_return_clusterid $RKE2_CLUSTER_NAME)
rancher_get_kubeconfig $RANCHER_URL $RKE2_CLUSTER_ID $RANCHER_APITOKEN samples/rke2-win/config/rke2.yaml
KUBECONFIG=$(pwd)/samples/rke2-win/config/rke2.yaml
chmod 600 $KUBECONFIG
# disables autoscaler (https://docs.rke2.io/helm#customizing-packaged-components-with-helmchartconfig, https://github.com/rancher/rke2-charts/blob/main/charts/rke2-coredns/rke2-coredns/1.33.005/values.yaml)
cat <<EOF | kubectl apply -f -
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: rke2-coredns
  namespace: kube-system
spec:
  valuesContent: |-
    autoscaler:
      enabled: false
EOF
k8s_install_certmanager v1.16.2
k8s_create_letsencryptclusterissuer nginx john.wick@intercontinentalhotel.org
```

- Create Windows VM:

```bash
RKE2_WINDOWS_STATICIP_NAME='ip-bthomas-rke2win'
gcloud compute addresses create $RKE2_WINDOWS_STATICIP_NAME --region=$GCLOUD_REGION
RKE2_WINDOWS_VM_NAME='vm-bthomas-rke2win'
googlecloud_create_vm $RKE2_WINDOWS_VM_NAME $GCLOUD_PROJECT_ID $GCLOUD_ZONE n1-standard-4 windows-2022 windows-cloud $GCLOUD_SUBNET $RKE2_WINDOWS_STATICIP_NAME
RKE2_WINDOWS_VM_RESET_OUTPUT=$(gcloud beta compute --project $GCLOUD_PROJECT_ID reset-windows-password $RKE2_WINDOWS_VM_NAME --zone $GCLOUD_ZONE --format=json --quiet)
RKE2_WINDOWS_VM_IP=$(echo "$RKE2_WINDOWS_VM_RESET_OUTPUT"  | jq -r '.ip_address')
# tip: you must add AzureAD\ before the username (ref. https://learn.microsoft.com/en-us/answers/questions/53514/credentials-supplied-to-the-package-were-not-recog)
RKE2_WINDOWS_VM_USERNAME=$(echo "$RKE2_WINDOWS_VM_RESET_OUTPUT"  | jq -r '.username')
RKE2_WINDOWS_VM_USERPWD=$(echo "$RKE2_WINDOWS_VM_RESET_OUTPUT"  | jq -r '.password  ')
RKE2_WINDOWS_REGISTERCOMMAND=$(rancher_return_clusterregistrationcommand $RKE2_CLUSTER_ID windows)
# defines an external IP for NGINX Ingress controller service (https://docs.rke2.io/networking/networking_services#nginx-ingress-controller, https://github.com/rancher/rke2-charts/blob/main/charts/rke2-ingress-nginx/rke2-ingress-nginx/4.10.502/values.yaml, https://support.tools/known-good-designs/loadbalancers/ingress-nginx-controller-on-rke2/)
cat <<EOF | kubectl apply -f -
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: rke2-ingress-nginx
  namespace: kube-system
spec:
  valuesContent: |-
    controller:
      service:
        enabled: true
        type: LoadBalancer
        externalIPs: ["${RKE2_LINUX_VM_IP}"]
EOF
```

- Install RKE2 worker on Windows VM:

```ps1
$credentials = Get-Credential
# establishes an interactive PowerShell session
Enter-PSSession -ComputerName $RKE2_WINDOWS_VM_IP -UseSSL -SessionOption (New-PSSessionOption -SkipCACheck -SkipCNCheck) -Credential $credentials
# invoke commands on the Windows Server VM remotely
$script = @'powershell -Command "Start-Process PowerShell -Verb RunAs"
Enable-WindowsOptionalFeature -Online -FeatureName containers -All
'@
Invoke-Command -ComputerName $RKE2_WINDOWS_VM_IP -ScriptBlock { $script } -UseSSL -SessionOption (New-PSSessionOption -SkipCACheck -SkipCNCheck) -Credential $credentials
Invoke-Command -ComputerName $RKE2_WINDOWS_VM_IP -ScriptBlock { $RKE2_WINDOWS_REGISTERCOMMAND } -UseSSL -SessionOption (New-PSSessionOption -SkipCACheck -SkipCNCheck) -Credential $credentials
# New-NetFirewallRule -DisplayName "RKE2 - Web App Traffic" -Direction Inbound -LocalPort 80 -Protocol TCP -Action Allow
# New-NetFirewallRule -DisplayName "RKE2 - Felix Traffic" -Direction Inbound -Protocol TCP -LocalPort 179 -Action Allow
# New-NetFirewallRule -DisplayName "RKE2 - K8s Pod Traffic" -Direction Inbound -Protocol TCP -LocalPort 30000-32767 -Action Allow
# $rke2BinLinkPath = "C:\var\lib\rancher\rke2\bin\"
# $rke2BinActualPath = (Get-Item -Path $linkPath -Force).Target
# New-NetFirewallRule -DisplayName "RKE2 - containerd application" -Direction Inbound -Program "$rke2BinActualPath\containerd.exe" -Action Allow
# Add-MpPreference -ExclusionPath $rke2BinActualPath
# Get-MpPreference | Select-Object -ExpandProperty ExclusionPath
# TODO: look at https://github.com/rancher/windows/issues/128
```

- From the Windows VM, open a cmd as Admin:

```bat
C:\var\lib\rancher\rke2\bin\crictl.exe -c C:\var\lib\rancher\rke2\agent\etc\crictl.yaml images
```

- Validate Windows container

```bash
kubectl run --restart=Never --image=mcr.microsoft.com/windows/nanoserver:ltsc2022 --rm -it test-nanoserver
```
