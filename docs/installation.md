# uServer-Web Installation Guide

This guide provides detailed instructions for installing and setting up the uServer-Web stack.

## Prerequisites

### For Docker Compose Deployment

Before installing uServer-Web with Docker Compose, ensure you have the following prerequisites installed:

- **Docker**: Version 20.10.0 or higher
- **Docker Compose**: Version 2.0.0 or higher
- **Bash**: Version 4.0 or higher
- **OpenSSL**: For certificate generation (optional)

### For Terraform Deployment (AWS)

For deploying to AWS using Terraform, you'll need:

- **Terraform**: Version 1.0.0 or higher
- **AWS CLI**: Configured with appropriate credentials
- **SSH Key Pair**: For accessing the EC2 instance

### For Kubernetes Deployment (Helm)

For deploying to Kubernetes using Helm, you'll need:

- **Kubernetes Cluster**: Version 1.19+
- **Helm**: Version 3.2.0+
- **kubectl**: Configured to access your cluster

## Installation Steps

### Docker Compose Deployment

#### 1. Clone the Repository

```bash
git clone https://github.com/ferdn4ndo/userver-web.git
cd userver-web
```

#### 2. Set Up the Environment

The uServer-Web stack provides a convenient setup script to configure the environment:

```bash
./scripts/userver.sh setup
```

This will create the necessary environment files with default settings. If you want to customize the setup, you can use the following options:

```bash
./scripts/userver.sh setup --monitor-host monitor.example.com --whoami-host whoami.example.com --update-hosts
```

#### 3. Generate SSL Certificates (Optional)

For local development, you can generate self-signed SSL certificates:

```bash
./scripts/userver.sh certs generate
```

For production environments, you should use Let's Encrypt certificates, which will be automatically generated when the stack is running.

#### 4. Start the Services

```bash
./scripts/userver.sh start --build --detach
```

This will build and start all the services in detached mode.

#### 5. Verify the Installation

You can verify that the services are running correctly:

```bash
./scripts/userver.sh status
```

You can also access the services in your browser:

- Monitor: http://monitor.userver.lan (or your custom domain)
- Whoami: http://whoami.userver.lan (or your custom domain)

### Terraform Deployment (AWS)

#### 1. Clone the Repository

```bash
git clone https://github.com/ferdn4ndo/userver-web.git
cd userver-web/terraform
```

#### 2. Initialize Terraform

```bash
terraform init
```

#### 3. Configure Deployment

Create a `terraform.tfvars` file with your configuration:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` to customize your deployment:

```bash
# Set your SSH key name
key_name = "your-ssh-key-name"

# Set your domain names
monitor_domain = "monitor.example.com"
whoami_domain = "whoami.example.com"

# Restrict SSH access to your IP
ssh_allowed_cidr = "203.0.113.0/24"  # Replace with your IP or CIDR block
```

#### 4. Deploy the Infrastructure

```bash
terraform apply
```

When prompted, type `yes` to confirm the deployment.

#### 5. Access the Services

After the deployment is complete, Terraform will output the public IP address and URLs for the services:

```
Outputs:

public_ip = "203.0.113.10"
monitor_url = "https://monitor.example.com"
whoami_url = "https://whoami.example.com"
```

If you're not using Route53 for DNS, you'll need to manually configure DNS records to point to the public IP address.

### Kubernetes Deployment (Helm)

#### 1. Clone the Repository

```bash
git clone https://github.com/ferdn4ndo/userver-web.git
cd userver-web
```

#### 2. Install the Helm Chart

```bash
helm install my-release ./helm/userver-web
```

#### 3. Customize the Deployment (Optional)

Create a `values.yaml` file with your custom configuration:

```yaml
global:
  domain:
    base: "example.com"
    monitor: "monitor"
    whoami: "whoami"
  tls:
    enabled: true
    certManager:
      enabled: true
      issuer: "letsencrypt-prod"

nginxProxy:
  service:
    type: LoadBalancer
```

Install the chart with your custom values:

```bash
helm install my-release ./helm/userver-web -f values.yaml
```

#### 4. Verify the Installation

```bash
kubectl get pods
```

You should see the following pods running:

```
NAME                                            READY   STATUS    RESTARTS   AGE
my-release-userver-web-nginx-proxy-abc123       1/1     Running   0          1m
my-release-userver-web-letsencrypt-def456       1/1     Running   0          1m
my-release-userver-web-monitor-ghi789           1/1     Running   0          1m
my-release-userver-web-whoami-jkl012            1/1     Running   0          1m
```

#### 5. Access the Services

If you're using an Ingress controller, you can access the services at:

- Monitor: https://monitor.example.com
- Whoami: https://whoami.example.com

If you're using a LoadBalancer service, you can get the external IP address:

```bash
kubectl get svc my-release-userver-web-nginx-proxy
```

## Customization

### Docker Compose Override (Optional)

You can customize the Docker Compose configuration by creating a `docker-compose.override.yml` file. An example file is provided at `docker-compose.override.yml.example`:

```bash
cp docker-compose.override.yml.example docker-compose.override.yml
```

Then edit the file to suit your needs.

### Terraform Variables (Optional)

You can customize the Terraform deployment by editing the `terraform.tfvars` file. See the [Terraform README](../terraform/README.md) for more information.

### Helm Values (Optional)

You can customize the Helm deployment by creating a `values.yaml` file. See the [Helm Chart README](../helm/userver-web/README.md) for more information.

## Troubleshooting

If you encounter any issues during installation, please refer to the [Troubleshooting](troubleshooting.md) guide.

## Next Steps

- [Usage](usage.md): Learn how to use the uServer-Web stack
- [Architecture](architecture.md): Understand the architecture of the uServer-Web stack
