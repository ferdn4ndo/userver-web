# uServer-Web Usage Guide

This guide provides detailed instructions for using the uServer-Web stack.

## Deployment Options

uServer-Web supports multiple deployment options:

1. **Docker Compose**: The default deployment option, suitable for local development and small production environments.
2. **Terraform (AWS)**: For deploying to AWS, using EC2 instances.
3. **Kubernetes (Helm)**: For deploying to Kubernetes clusters.

## Command Line Interface

The uServer-Web stack provides a unified command-line interface through the `userver.sh` script. This script provides commands for managing the stack, including setup, certificate management, testing, service control, and upgrading.

### General Usage

```bash
./scripts/userver.sh [command] [options]
```

To get help for a specific command:

```bash
./scripts/userver.sh [command] --help
```

### Available Commands

#### Setup

Set up the environment files:

```bash
./scripts/userver.sh setup
```

Options:
- `-m, --monitor-host HOST`: Set the monitor virtual host (default: monitor.userver.lan)
- `-w, --whoami-host HOST`: Set the whoami virtual host (default: whoami.userver.lan)
- `-u, --update-hosts`: Update /etc/hosts file with the virtual hosts
- `-h, --help`: Display help message

#### Certificate Management

Generate self-signed certificates for local development:

```bash
./scripts/userver.sh certs generate
```

Options for `generate`:
- `-d, --domain DOMAIN`: Generate certificate for specific domain(s)
- `-y, --yes`: Skip confirmation prompts
- `-h, --help`: Display help message

Reset certificates:

```bash
./scripts/userver.sh certs reset
```

Options for `reset`:
- `-y, --yes`: Skip confirmation prompts
- `-h, --help`: Display help message

#### Service Control

Start services:

```bash
./scripts/userver.sh start
```

Start services in detached mode with build:

```bash
./scripts/userver.sh start --detach --build
```

Stop services:

```bash
./scripts/userver.sh stop
```

Restart services:

```bash
./scripts/userver.sh restart
```

Check service status:

```bash
./scripts/userver.sh status
```

Options for service control commands:
- `-d, --detach`: Run containers in the background (for start/restart)
- `-b, --build`: Build images before starting containers (for start/restart)
- `-h, --help`: Display help message

#### Testing

Run all tests:

```bash
./scripts/userver.sh test
```

Run specific test types:

```bash
./scripts/userver.sh test --unit-tests
./scripts/userver.sh test --integration
./scripts/userver.sh test --e2e
./scripts/userver.sh test --shellcheck
```

Options:
- `-u, --unit-tests`: Run unit tests only
- `-i, --integration`: Run integration tests only
- `-e, --e2e`: Run end-to-end tests only
- `-s, --shellcheck`: Run ShellCheck tests only
- `-a, --all`: Run all tests (default)
- `-h, --help`: Display help message

#### Upgrade

Upgrade the stack to the latest version:

```bash
./scripts/userver.sh upgrade
```

Options:
- `-b, --backup`: Create a backup before upgrading
- `-p, --pull-only`: Only pull the latest images without restarting
- `-f, --force`: Force upgrade without confirmation
- `-h, --help`: Display help message

## Terraform Deployment (AWS)

To deploy uServer-Web on AWS using Terraform:

1. Navigate to the Terraform directory:

```bash
cd terraform
```

2. Initialize Terraform:

```bash
terraform init
```

3. Create a `terraform.tfvars` file with your configuration:

```bash
cp terraform.tfvars.example terraform.tfvars
```

4. Edit `terraform.tfvars` to customize your deployment:

```bash
# Set your SSH key name
key_name = "your-ssh-key-name"

# Set your domain names
monitor_domain = "monitor.example.com"
whoami_domain = "whoami.example.com"

# Restrict SSH access to your IP
ssh_allowed_cidr = "203.0.113.0/24"  # Replace with your IP or CIDR block
```

5. Plan the deployment:

```bash
terraform plan
```

6. Apply the configuration:

```bash
terraform apply
```

7. When the deployment is complete, Terraform will output the public IP address and URLs for the services.

For more information, see the [Terraform README](../terraform/README.md).

## Kubernetes Deployment (Helm)

To deploy uServer-Web on Kubernetes using Helm:

1. Install the chart with the release name `my-release`:

```bash
helm install my-release ./helm/userver-web
```

2. To customize the deployment, create a `values.yaml` file:

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

3. Install the chart with your custom values:

```bash
helm install my-release ./helm/userver-web -f values.yaml
```

4. To uninstall the chart:

```bash
helm uninstall my-release
```

For more information, see the [Helm Chart README](../helm/userver-web/README.md).

## Web Interfaces

### Monitor

The monitor service provides a web interface for monitoring the resource usage of all containers in the stack. By default, it is available at:

```
http://monitor.userver.lan
```

### Whoami

The whoami service provides a simple health check endpoint that returns information about the request. By default, it is available at:

```
http://whoami.userver.lan
```

## Adding Custom Services

You can add custom services to the stack by creating a `docker-compose.override.yml` file. An example file is provided at `docker-compose.override.yml.example`.

For example, to add a custom web service:

```yaml
services:
  userver-custom-service:
    image: nginx:alpine
    container_name: userver-custom-service
    expose:
      - 80
    environment:
      - VIRTUAL_HOST=custom.userver.lan
      - LETSENCRYPT_HOST=custom.userver.lan
      - LETSENCRYPT_EMAIL=admin@example.com
    volumes:
      - ./custom-service/html:/usr/share/nginx/html
```

Then update your hosts file to include the new domain:

```bash
sudo echo "127.0.0.1 custom.userver.lan" | sudo tee -a /etc/hosts
```

And restart the services:

```bash
./scripts/userver.sh restart
```

## Troubleshooting

If you encounter any issues while using the uServer-Web stack, please refer to the [Troubleshooting](troubleshooting.md) guide.
