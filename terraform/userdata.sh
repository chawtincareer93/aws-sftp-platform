#!/bin/bash

apt update -y
apt install -y curl

# create 4GB swapfile for increase performance but maintains EC2 usage within free tier limits.
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

echo '/swapfile swap swap defaults 0 0' >> /etc/fstab

# install k3s but disable traefik and metrics-server which can be resource intensive and not needed for this demo.
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable metrics-server" sh -

# wait for k3s to be ready
while [ ! -f /etc/rancher/k3s/k3s.yaml ]; do
  echo "waiting for k3s..."
  sleep 5
done

mkdir -p /home/ubuntu/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config

kubectl get nodes