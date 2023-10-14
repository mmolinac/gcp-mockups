#!/bin/sh
export DEBIAN_FRONTEND=noninteractive
KUBEVERSION="1.28.0"
KUBEVERSIONFULL="${KUBEVERSION}-1.1"
echo "Starting software installation" | tee /tmp/startup.log
echo "Installing packages as user `whoami`" | tee -a /tmp/startup.log
apt-get update
apt install -y jq bash-completion

NAME=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/hostname")
IP=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip")
METADATA=$(curl -f -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/attributes/?recursive=True" | jq 'del(.["startup-script"])')

# Add an entry to /etc/hosts
for i in `seq 0 2`
do
  fhname="onpremclust0$i"
  grep $fhname /etc/hosts > /dev/null || echo "`host ${fhname}|awk '{print $4}'` ${fhname}" >> /etc/hosts
done
# Add modules to load for Kubernetes
# Install modules and let iptables see bridged traffic
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

(lsmod | grep overlay) || modprobe overlay
(lsmod | grep br_netfilter) || modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sysctl --system
sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward

# Install packages
apt update
apt-get install -y apt-transport-https ca-certificates curl gnupg

# Download the public signing key  for the Kubernetes package repositories
test -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg || (curl -fsSL \
  https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | \
  gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg)

# Add the appropriate Kubernetes apt repository
# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
test -f /etc/apt/sources.list.d/kubernetes.list || \
  (echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' |\
  tee /etc/apt/sources.list.d/kubernetes.list)
apt-get update

# Be aware that order does matter:
for kubepkg in kubectl kubelet kubeadm
do
  (dpkg -l ${kubepkg} | grep "^ii" >/dev/null) || (apt-get install -y ${kubepkg}=${KUBEVERSIONFULL} && apt-mark hold ${kubepkg})
done

# Install Docker
test -f /etc/apt/keyrings/docker.gpg || (curl -fsSL \
  https://download.docker.com/linux/debian/gpg | gpg --dearmor -o \
  /etc/apt/keyrings/docker.gpg && chmod a+r /etc/apt/keyrings/docker.gpg)

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update
apt-get install -y containerd.io netcat-openbsd

# Create configuration files
mkdir -p /etc/containerd
grep 'disabled_plugins' /etc/containerd/config.toml | grep cri > /dev/null && \
  (containerd config default | sed 's/SystemdCgroup = false/SystemdCgroup = true/g'\
  | tee /etc/containerd/config.toml \ && systemctl restart containerd)

## Now give directions to build the cluster
echo "Installation of software has finished. Now follow these directions:" | tee -a /tmp/startup.log
if [ "`hostname -s`" = "onpremclust00" ]; then
  ## This is the control plane
  cat <<EOF | tee -a /tmp/startup.log
- This is the control plane. Initialize the cluster this way:
  kubeadm init --kubernetes-version ${KUBEVERSION} --apiserver-advertise-address=`hostname -i` --control-plane-endpoint `hostname -s`:6443 --cri-socket=unix:///var/run/containerd/containerd.sock --pod-network-cidr 192.168.0.0/16 --upload-certs | tee $HOME/cp.out
EOF
else
  ## This is a worker node
  cat <<EOF | tee -a /tmp/startup.log
- This is a worker node. Add it to the cluster through directions given on /tmp/startup.log there.
  Or you can get it from the master node by doing: kubeadm token create --print-join-command
  A sample command would be: kubeadm join onpremclust00:6443 --token kcsof9.aydsty1aaei9hut8 --discovery-token-ca-cert-hash sha256:9a46836e2e36773aff8a478c1ad050ea059cd28d00564258194885276d9ef5f6
EOF
fi
cat <<EOF | tee -a /tmp/startup.log
Check node taints by doing:

kubectl describe nodes  | grep -i taint

Untaint all nodes, including cp node, by doing:

kubectl taint nodes --all node-role.kubernetes.io/control-plane-

Autocompletion with: 

source <(kubectl completion bash) # set up autocomplete in bash into the current shell, bash-completion package should be installed first.
echo "source <(kubectl completion bash)" >> ~/.bashrc # add autocomplete permanently to your bash shell.

Please also add the following aliases:

alias k=kubectl
complete -o default -F __start_kubectl k
export do="--dry-run=client -o yaml"
export now="--force --grace-period 0"

Don't forget: export KUBECONFIG=/etc/kubernetes/admin.conf
 or to do: mkdir -p \$HOME/.kube && sudo cat /etc/kubernetes/admin.conf > \$HOME/.kube/config
... and right away apply this to have the network configured with one of the following options:

1) Calico: kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
2) Cilium:
  - curl -LO https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz
  - sudo tar xzvfC cilium-linux-amd64.tar.gz /usr/local/bin && rm cilium-linux-amd64.tar.gz
  - cilium install

Remember that you have help available here:
https://kubernetes.io/docs/
https://kubernetes.io/blog/
EOF
