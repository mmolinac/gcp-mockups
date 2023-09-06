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
grep $IP /etc/hosts > /dev/null || echo "`hostname -i` `hostname -s`" >> /etc/hosts

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
apt-get install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin netcat-openbsd

# Create configuration files
mkdir -p /etc/containerd
grep 'disabled_plugins' /etc/containerd/config.toml | grep cri > /dev/null && \
  (containerd config default | tee /etc/containerd/config.toml \
  && systemctl restart containerd)

## Now give directions to build the cluster
echo "Installation of software has finished. Now follow these directions:" | tee -a /tmp/startup.log
if [ "`hostname -s`" = "onpremclust00" ]; then
  ## This is the control plane
  echo "- This is the control plane. Initialize the cluster this way:" | tee -a /tmp/startup.log
  echo "kubeadm init --kubernetes-version ${KUBEVERSION} --apiserver-advertise-address=`hostname -i` --control-plane-endpoint `hostname -s`:6443 --cri-socket=unix:///var/run/containerd/containerd.sock --pod-network-cidr 192.168.0.0/16 --upload-certs | tee $HOME/cp.out" | tee -a /tmp/startup.log
else
  ## This is a worker node
  echo "- This is a worker node. Add it to the cluster through directions given on /tmp/startup.log there." | tee -a /tmp/startup.log
fi
echo "Autocompletion with: echo 'source <(kubectl completion bash)' >> \$HOME/.bashrc" | tee -a /tmp/startup.log
