#!/bin/bash

set -e

cd ../terraform
terraform init
terraform apply -auto-approve

INSTANCE_IP=$(terraform output -raw instance_public_ip)

sleep 60

scp -i ~/.ssh/sftpgo-keypair.pem -r ../kubernetes ubuntu@$INSTANCE_IP:/home/ubuntu/

ssh -i ~/.ssh/sftpgo-keypair.pem ubuntu@$INSTANCE_IP << 'EOF'
sudo KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl apply -f /home/ubuntu/kubernetes/namespace.yaml
sudo KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl apply -f /home/ubuntu/kubernetes/pvc.yaml -f /home/ubuntu/kubernetes/sftpgo-deploy.yaml -f /home/ubuntu/kubernetes/sftpgo-service.yaml -f /home/ubuntu/kubernetes/ingress.yaml
EOF
