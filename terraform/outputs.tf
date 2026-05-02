output "instance_public_ip" {
  value       = aws_instance.k3s.public_ip
  description = "Public IP address of the K3s EC2 instance"
}

output "nlb_dns_name" {
  value       = aws_lb.nlb.dns_name
  description = "Single access point for both SFTP (port 2022) and HTTP (port 80)"
}

output "sftp_endpoint" {
  value       = "sftp://${aws_lb.nlb.dns_name}:2022"
  description = "SFTP endpoint for SFTP access on port 2022"
}

output "http_endpoint" {
  value       = "http://${aws_lb.nlb.dns_name}:80"
  description = "HTTP endpoint for web access"
}
