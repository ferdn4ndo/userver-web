# Terraform Configuration for uServer-Web

This directory contains Terraform configuration for deploying the uServer-Web stack on AWS.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (v1.0.0 or higher)
- AWS account with appropriate permissions
- AWS CLI configured with your credentials

## Files

- `main.tf`: Main Terraform configuration file
- `variables.tf`: Variable definitions
- `terraform.tfvars.example`: Example variable values (copy to `terraform.tfvars` and customize)

## Usage

1. Initialize Terraform:

```bash
terraform init
```

2. Create a `terraform.tfvars` file with your configuration:

```bash
cp terraform.tfvars.example terraform.tfvars
```

3. Edit `terraform.tfvars` to customize your deployment:

```bash
# Set your SSH key name
key_name = "your-ssh-key-name"

# Set your domain names
monitor_domain = "monitor.example.com"
whoami_domain = "whoami.example.com"

# Restrict SSH access to your IP
ssh_allowed_cidr = "203.0.113.0/24"  # Replace with your IP or CIDR block
```

4. Plan the deployment:

```bash
terraform plan
```

5. Apply the configuration:

```bash
terraform apply
```

6. When the deployment is complete, Terraform will output the public IP address and URLs for the services.

## DNS Configuration

If you want to automatically configure DNS records in Route53:

1. Set `create_dns_records` to `true` in `terraform.tfvars`
2. Set `route53_zone_id` to your Route53 hosted zone ID

```bash
create_dns_records = true
route53_zone_id = "Z1234567890ABC"
```

If you're not using Route53, you'll need to manually configure DNS records to point to the public IP address of the EC2 instance.

## Customization

You can customize the deployment by modifying the variables in `terraform.tfvars`:

- `aws_region`: AWS region to deploy to
- `vpc_cidr`: CIDR block for the VPC
- `public_subnet_cidr`: CIDR block for the public subnet
- `ssh_allowed_cidr`: CIDR block allowed to SSH into the instance
- `ami_id`: AMI ID for the EC2 instance
- `instance_type`: Instance type for the EC2 instance
- `key_name`: Name of the SSH key pair to use
- `monitor_domain`: Domain name for the monitor service
- `whoami_domain`: Domain name for the whoami service
- `create_dns_records`: Whether to create DNS records in Route53
- `route53_zone_id`: Route53 hosted zone ID for DNS records

## Cleanup

To destroy the infrastructure:

```bash
terraform destroy
```

## Security Considerations

- The default configuration allows SSH access from any IP address (`0.0.0.0/0`). For production use, restrict this to your IP address or VPN.
- The EC2 instance is deployed in a public subnet. For production use, consider using a private subnet with a bastion host or VPN for SSH access.
- The default configuration uses a t3.small instance type. For production use, consider using a larger instance type.
- The default configuration uses a 20GB root volume. For production use, consider using a larger volume or adding additional volumes.
