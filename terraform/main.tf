# Terraform configuration for uServer-Web
# This configuration deploys the uServer-Web stack on AWS

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "aws" {
  region = var.aws_region
}

# VPC for the uServer-Web stack
resource "aws_vpc" "userver_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "userver-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "userver_igw" {
  vpc_id = aws_vpc.userver_vpc.id

  tags = {
    Name = "userver-igw"
  }
}

# Public Subnet
resource "aws_subnet" "userver_public_subnet" {
  vpc_id                  = aws_vpc.userver_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "userver-public-subnet"
  }
}

# Route Table
resource "aws_route_table" "userver_public_rt" {
  vpc_id = aws_vpc.userver_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.userver_igw.id
  }

  tags = {
    Name = "userver-public-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "userver_public_rt_assoc" {
  subnet_id      = aws_subnet.userver_public_subnet.id
  route_table_id = aws_route_table.userver_public_rt.id
}

# Security Group
resource "aws_security_group" "userver_sg" {
  name        = "userver-sg"
  description = "Security group for uServer-Web"
  vpc_id      = aws_vpc.userver_vpc.id

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  # Outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "userver-sg"
  }
}

# EC2 Instance
resource "aws_instance" "userver_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.userver_public_subnet.id
  vpc_security_group_ids = [aws_security_group.userver_sg.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = <<-EOF
              #!/bin/bash
              # Install Docker
              apt-get update
              apt-get install -y apt-transport-https ca-certificates curl software-properties-common
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
              add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
              apt-get update
              apt-get install -y docker-ce docker-ce-cli containerd.io

              # Install Docker Compose
              curl -L "https://github.com/docker/compose/releases/download/v2.15.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose

              # Clone uServer-Web repository
              git clone https://github.com/ferdn4ndo/userver-web.git /opt/userver-web
              cd /opt/userver-web

              # Set up environment
              chmod +x scripts/*.sh
              ./scripts/userver.sh setup --monitor-host ${var.monitor_domain} --whoami-host ${var.whoami_domain}

              # Generate certificates
              ./scripts/userver.sh certs generate --yes

              # Create Docker network
              docker network create nginx-proxy || true

              # Start services
              ./scripts/userver.sh start --build --detach
              EOF

  tags = {
    Name = "userver-instance"
  }
}

# Elastic IP
resource "aws_eip" "userver_eip" {
  instance = aws_instance.userver_instance.id
  vpc      = true

  tags = {
    Name = "userver-eip"
  }
}

# Route53 Records (if domains are managed by Route53)
resource "aws_route53_record" "monitor_record" {
  count   = var.create_dns_records ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.monitor_domain
  type    = "A"
  ttl     = "300"
  records = [aws_eip.userver_eip.public_ip]
}

resource "aws_route53_record" "whoami_record" {
  count   = var.create_dns_records ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.whoami_domain
  type    = "A"
  ttl     = "300"
  records = [aws_eip.userver_eip.public_ip]
}

# Output
output "public_ip" {
  value = aws_eip.userver_eip.public_ip
}

output "monitor_url" {
  value = "https://${var.monitor_domain}"
}

output "whoami_url" {
  value = "https://${var.whoami_domain}"
}
