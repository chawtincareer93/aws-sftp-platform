variable "aws_region" {
  default = "eu-west-2"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "key_name" {
  description = "Existing AWS key pair"
}

variable "allowed_ssh_cidr" {
  description = "CIDR range allowed to SSH directly to the EC2 instance on port 22. Use your public IP/32 for security."
  default     = "0.0.0.0/0"
}
