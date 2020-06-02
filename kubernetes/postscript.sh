#!/bin/bash -v

echo "Start script.  The time is now $(date -R)!" | tee -a /root/output.txt
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - | tee -a /root/output.txt
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list
apt-get update | tee -a /root/output.txt
apt-get install -y kubelet kubeadm kubectl kubernetes-cni | tee -a /root/output.txt
apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  software-properties-common \
  gnupg2 \
  socat \
  jq \
  httpie \
  git \
  sshpass \
  bash-completion \
  net-tools \
  nano \
  mc \
  tmux \
  docker.io \
  apparmor-profiles-extra \
  apparmor-utils \
  python-docker \
  python-pip | tee -a /root/output.txt

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - | tee -a /root/output.txt
add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable" | tee -a /root/output.txt

apt-get update && apt-get install -y \
  containerd.io=1.2.13-1 \
  docker-ce=5:19.03.8~3-0~ubuntu-$(lsb_release -cs) \
  docker-ce-cli=5:19.03.8~3-0~ubuntu-$(lsb_release -cs) | tee -a /root/output.txt

cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "1000m"
  },
  "storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# Restart docker.
systemctl daemon-reload
systemctl restart docker

echo "Script done.  The time is now $(date -R)!" | tee -a /root/output.txt
