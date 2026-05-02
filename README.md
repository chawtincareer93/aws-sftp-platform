# AWS SFTPGo Platform

# overview

A lightweight cloud-native managed SFTP platform built using:

- Terraform
- AWS
- k3s Kubernetes
- SFTPGo

# features

Infrastructure as Code
Kubernetes workloads
Network Load Balancer
- Persistent storage
- SFTP access
- Web administration UI


# deployment

## requirements

- Terraform
- AWS CLI
- kubectl
- SSH keypair

## deploy

```bash
./scripts/deploy.sh 

## access
### sftp
sftp -P 2022 sftpgo-nlb-xxxxx.elb.eu-west-2.amazonaws.com

### http
http://sftpgo-nlb-xxxxx.elb.eu-west-2.amazonaws.com:80

