resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "sftpgo-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "sftpgo-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-2a"

  tags = {
    Name = "sftpgo-public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "ec2" {
  name        = "sftpgo-sg"
  description = "Allow direct SSH from your IP and SFTP/HTTP from the NLB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    from_port   = 2022
    to_port     = 2022
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sftpgo-ec2-sg"
  }
}

resource "aws_security_group" "nlb" {
  name        = "sftpgo-nlb-sg"
  description = "Security group for NLB handling SFTP and HTTP"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 2022
    to_port     = 2022
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sftpgo-nlb-sg"
  }
}

resource "aws_instance" "k3s" {
  ami                    = "ami-0d114020bf27f27cf"
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  key_name               = var.key_name

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
  }

  user_data = file("userdata.sh")

  tags = {
    Name = "sftpgo-k3s"
  }
}

# Single Network Load Balancer for both SFTP (2022) and HTTP (80)
resource "aws_lb" "nlb" {
  name               = "sftpgo-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.public.id]

  enable_deletion_protection = false

  tags = {
    Name = "sftpgo-nlb"
  }
}

# Target group for SFTP traffic
resource "aws_lb_target_group" "ssh" {
  name     = "sftp-target-group"
  port     = 2022
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 3
    interval            = 10
    port                = "2022"
    protocol            = "TCP"
  }

  tags = {
    Name = "ssh-target-group"
  }
}

# Target group for HTTP traffic
resource "aws_lb_target_group" "http" {
  name     = "http-target-group"
  port     = 80
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 3
    interval            = 10
    port                = "80"
    protocol            = "TCP"
  }

  tags = {
    Name = "http-target-group"
  }
}

# NLB target group attachment for SFTP
resource "aws_lb_target_group_attachment" "sftp" {
  target_group_arn = aws_lb_target_group.ssh.arn
  target_id        = aws_instance.k3s.id
  port             = 2022
}

# NLB target group attachment for HTTP
resource "aws_lb_target_group_attachment" "http" {
  target_group_arn = aws_lb_target_group.http.arn
  target_id        = aws_instance.k3s.id
  port             = 80
}

# NLB listener for SFTP
resource "aws_lb_listener" "sftp" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 2022
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ssh.arn
  }
}

# NLB listener for HTTP
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http.arn
  }
}