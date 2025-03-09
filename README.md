# uServer Web

[![E2E test status](https://github.com/ferdn4ndo/userver-web/actions/workflows/test_e2e.yml/badge.svg?branch=main)](https://github.com/ferdn4ndo/userver-web/actions)
[![GitLeaks test status](https://github.com/ferdn4ndo/userver-web/actions/workflows/test_code_leaks.yml/badge.svg?branch=main)](https://github.com/ferdn4ndo/userver-web/actions)
[![ShellCheck test status](https://github.com/ferdn4ndo/userver-web/actions/workflows/test_code_quality.yml/badge.svg?branch=main)](https://github.com/ferdn4ndo/userver-web/actions)
[![Release](https://img.shields.io/github/v/release/ferdn4ndo/userver-web)](https://github.com/ferdn4ndo/userver-web/releases)
[![MIT license](https://img.shields.io/badge/license-MIT-brightgreen.svg)](https://opensource.org/licenses/MIT)

Web server microservices stack based on [nginx-proxy](https://github.com/nginx-proxy/nginx-proxy) for DNS reverse proxy, [letsencrypt-nginx-proxy-companion](https://github.com/nginx-proxy/docker-letsencrypt-nginx-proxy-companion) for SSL support and auto-renewal, a lightweight containers resource usage monitoring by [docker-containers-monitor](https://github.com/ferdn4ndo/docker-containers-monitor), and a 'Who Am I?' container for basic health checking using [whoami](https://github.com/traefik/whoami).

It's part of the [uServer](https://github.com/users/ferdn4ndo/projects/1) stack project.

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Usage](#usage)
  - [Setup Environment](#setup-environment)
  - [Certificate Management](#certificate-management)
  - [Running Services](#running-services)
  - [Testing](#testing)
  - [Upgrading](#upgrading)
- [Deployment Options](#deployment-options)
  - [Docker Compose](#docker-compose)
  - [Terraform (AWS)](#terraform-aws)
  - [Kubernetes (Helm)](#kubernetes-helm)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Reverse Proxy**: Nginx-based reverse proxy for routing requests to appropriate services
- **SSL Support**: Automatic SSL certificate generation and renewal via Let's Encrypt
- **Container Monitoring**: Lightweight resource usage monitoring for all containers
- **Health Checking**: Basic health check endpoint via the 'Who Am I?' service
- **Comprehensive Testing**: Unit, integration, and end-to-end tests
- **Easy Management**: Unified command-line interface for all operations
- **Multiple Deployment Options**: Support for Docker Compose, Terraform (AWS), and Kubernetes (Helm)

## Architecture

The uServer-Web stack consists of the following components:

- **userver-nginx-proxy**: Reverse proxy based on nginx for routing requests
- **userver-letsencrypt**: SSL certificate management via Let's Encrypt
- **userver-monitor**: Container resource usage monitoring
- **userver-whoami**: Basic health checking service

For a detailed architecture overview, see the [Architecture Documentation](docs/architecture.md).

## Getting Started

### Prerequisites

- Docker and Docker Compose
- Bash shell
- OpenSSL (for certificate generation)

For other deployment options, additional prerequisites may apply. See the [Deployment Options](#deployment-options) section.

### Installation

1. Clone the repository:

```bash
git clone https://github.com/ferdn4ndo/userver-web.git
cd userver-web
```

2. Set up the environment:

```bash
./scripts/userver.sh setup
```

This will create the necessary environment files with default settings.

## Usage

### Setup Environment

The setup script provides options for configuring the environment:

```bash
./scripts/userver.sh setup --help
```

Example with custom domain names:

```bash
./scripts/userver.sh setup --monitor-host monitor.example.com --whoami-host whoami.example.com --update-hosts
```

### Certificate Management

Generate self-signed certificates for local development:

```bash
./scripts/userver.sh certs generate
```

Generate certificates for specific domains:

```bash
./scripts/userver.sh certs generate --domain example.com --domain api.example.com
```

Reset certificates:

```bash
./scripts/userver.sh certs reset
```

### Running Services

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

### Testing

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

### Upgrading

Upgrade the stack to the latest version:

```bash
./scripts/userver.sh upgrade
```

Create a backup before upgrading:

```bash
./scripts/userver.sh upgrade --backup
```

Only pull the latest images without restarting:

```bash
./scripts/userver.sh upgrade --pull-only
```

## Deployment Options

### Docker Compose

The default deployment option is Docker Compose, which is suitable for local development and small production environments.

```bash
./scripts/userver.sh start --detach --build
```

For more information, see the [Usage](#usage) section.

### Terraform (AWS)

For deploying to AWS, you can use the provided Terraform configuration:

```bash
cd terraform
terraform init
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your configuration
terraform apply
```

For more information, see the [Terraform README](terraform/README.md).

### Kubernetes (Helm)

For deploying to Kubernetes, you can use the provided Helm chart:

```bash
helm install my-release ./helm/userver-web
```

For more information, see the [Helm Chart README](helm/userver-web/README.md).

## Development

The project follows SOLID principles and aims for high test coverage. The codebase is organized as follows:

- **scripts/**: Management scripts for setup, testing, and service control
- **nginx-proxy/**: Nginx proxy configuration
- **letsencrypt/**: Let's Encrypt configuration
- **monitor/**: Container monitoring configuration
- **whoami/**: Health check service configuration
- **certs/**: SSL certificates storage
- **terraform/**: Terraform configuration for AWS deployment
- **helm/**: Helm chart for Kubernetes deployment
- **docs/**: Detailed documentation

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

For more information, see the [Contributing Guidelines](CONTRIBUTING.md).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
