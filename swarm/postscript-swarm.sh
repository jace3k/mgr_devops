#!/bin/bash -v

echo "Start script.  The time is now $(date -R)!" | tee -a /root/output.txt
apt-get update | tee -a /root/output.txt
apt-get install -y \
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
  python-pip | tee -a /root/output.txt

echo "Script done.  The time is now $(date -R)!" | tee -a /root/output.txt
