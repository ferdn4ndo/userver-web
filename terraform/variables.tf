# Variables for uServer-Web Terraform configuration

variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed to SSH into the instance"
  type        = string
  default     = "0.0.0.0/0"  # Note: For production, restrict this to your IP or VPN
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance (Ubuntu 20.04 LTS)"
  type        = string
  default     = "ami-0261755bbcb8c4a84"  # Ubuntu 20.04 LTS in us-east-1
}

variable "instance_type" {
  description = "Instance type for the EC2 instance"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "Name of the SSH key pair to use"
  type        = string
}

variable "monitor_domain" {
  description = "Domain name for the monitor service"
  type        = string
}

variable "whoami_domain" {
  description = "Domain name for the whoami service"
  type        = string
}

variable "create_dns_records" {
  description = "Whether to create DNS records in Route53"
  type        = bool
  default     = false
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for DNS records"
  type        = string
  default     = ""
}
