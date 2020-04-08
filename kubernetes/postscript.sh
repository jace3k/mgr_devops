#!/bin/bash -v

echo "Start script.  The time is now $(date -R)!" >> /root/output.txt
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - >> /root/output.txt
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" >> /etc/apt/sources.list.d/kubernetes.list
apt-get update >> /root/output.txt
apt-get install -y kubelet kubeadm kubectl kubernetes-cni >> /root/output.txt
apt install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  software-properties-common \
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
  python-pip >> /root/output.txt

echo "Script done.  The time is now $(date -R)!" >> /root/output.txt
