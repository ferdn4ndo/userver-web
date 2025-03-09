# uServer-Web Troubleshooting Guide

This guide provides solutions to common issues you might encounter when using the uServer-Web stack.

## Table of Contents

- [Common Issues](#common-issues)
  - [Services Won't Start](#services-wont-start)
  - [Certificate Issues](#certificate-issues)
  - [Network Issues](#network-issues)
  - [Permission Issues](#permission-issues)
- [Diagnostic Tools](#diagnostic-tools)
- [Logs](#logs)
- [FAQ](#faq)

## Common Issues

### Services Won't Start

#### Issue: Docker Compose fails to start services

**Symptoms:**
- Error messages when running `./scripts/userver.sh start`
- Services not appearing when running `./scripts/userver.sh status`

**Possible Causes and Solutions:**

1. **Docker daemon not running**

   Check if Docker is running:
   ```bash
   docker info
   ```

   If it's not running, start the Docker daemon:
   ```bash
   sudo systemctl start docker
   ```

2. **Port conflicts**

   If ports 80 or 443 are already in use by another service, you'll need to stop that service or configure uServer-Web to use different ports.

   Check if ports are in use:
   ```bash
   sudo lsof -i :80
   sudo lsof -i :443
   ```

   Stop the conflicting service or modify the `docker-compose.override.yml` file to use different ports.

3. **Network issues**

   The `nginx-proxy` network might not exist or have issues:
   ```bash
   docker network ls | grep nginx-proxy
   ```

   If it doesn't exist, create it:
   ```bash
   docker network create nginx-proxy
   ```

   If it exists but has issues, remove and recreate it:
   ```bash
   docker network rm nginx-proxy
   docker network create nginx-proxy
   ```

4. **Environment files missing or misconfigured**

   Run the setup script to ensure all environment files are properly configured:
   ```bash
   ./scripts/userver.sh setup
   ```

### Certificate Issues

#### Issue: SSL certificates not working

**Symptoms:**
- Browser warnings about invalid certificates
- Services accessible via HTTP but not HTTPS

**Possible Causes and Solutions:**

1. **Self-signed certificates not generated**

   Generate self-signed certificates:
   ```bash
   ./scripts/userver.sh certs generate
   ```

2. **Let's Encrypt certificates not being issued**

   Check the Let's Encrypt container logs:
   ```bash
   docker logs userver-letsencrypt
   ```

   Common issues include:
   - Domain not pointing to your server (DNS issues)
   - Rate limiting (too many certificate requests)
   - Incorrect email address in configuration

3. **Certificate files have incorrect permissions**

   Check and fix permissions:
   ```bash
   sudo chown -R $(whoami):$(whoami) ./certs
   sudo chmod -R 755 ./certs
   ```

### Network Issues

#### Issue: Cannot access services via domain names

**Symptoms:**
- Unable to access services via configured domain names
- "Site cannot be reached" errors in browser

**Possible Causes and Solutions:**

1. **Hosts file not configured**

   For local development, ensure your hosts file includes the domain names:
   ```bash
   sudo echo "127.0.0.1 monitor.userver.lan" | sudo tee -a /etc/hosts
   sudo echo "127.0.0.1 whoami.userver.lan" | sudo tee -a /etc/hosts
   ```

   Or use the setup script with the `--update-hosts` option:
   ```bash
   ./scripts/userver.sh setup --update-hosts
   ```

2. **Nginx proxy configuration issues**

   Check the nginx-proxy container logs:
   ```bash
   docker logs userver-nginx-proxy
   ```

   Look for configuration errors or issues with virtual hosts.

3. **Docker network issues**

   Ensure all containers are on the same network:
   ```bash
   docker network inspect nginx-proxy
   ```

   If containers are missing, restart the services:
   ```bash
   ./scripts/userver.sh restart
   ```

### Permission Issues

#### Issue: Permission denied errors

**Symptoms:**
- "Permission denied" errors in logs
- Services failing to start or access files

**Possible Causes and Solutions:**

1. **Script permissions**

   Ensure all scripts are executable:
   ```bash
   chmod +x scripts/*.sh
   ```

2. **Docker socket permissions**

   If the Docker socket has incorrect permissions:
   ```bash
   sudo chmod 666 /var/run/docker.sock
   ```

   Note: This is a temporary solution. For a more secure approach, add your user to the docker group:
   ```bash
   sudo usermod -aG docker $(whoami)
   ```
   Then log out and log back in.

3. **Volume mount permissions**

   If container volumes have permission issues:
   ```bash
   sudo chown -R $(whoami):$(whoami) ./certs ./nginx-proxy/logs ./vhost
   ```

## Diagnostic Tools

### Check Service Status

```bash
./scripts/userver.sh status
```

### View Container Logs

```bash
docker logs userver-nginx-proxy
docker logs userver-letsencrypt
docker logs userver-monitor
docker logs userver-whoami
```

### Check Network Configuration

```bash
docker network inspect nginx-proxy
```

### Validate Docker Compose Configuration

```bash
docker-compose config
```

## Logs

Logs for the nginx-proxy service are stored in the `nginx-proxy/logs` directory. You can view them directly:

```bash
cat nginx-proxy/logs/access.log
cat nginx-proxy/logs/error.log
```

## FAQ

### Q: How do I add a new service to the stack?

A: Create a `docker-compose.override.yml` file based on the example provided, add your service configuration, and restart the stack with `./scripts/userver.sh restart`.

### Q: How do I update the stack to the latest version?

A: Use the upgrade command:
```bash
./scripts/userver.sh upgrade --backup
```

### Q: How do I change the domain names after initial setup?

A: Run the setup script again with the new domain names:
```bash
./scripts/userver.sh setup --monitor-host new-monitor.example.com --whoami-host new-whoami.example.com --update-hosts
```

### Q: How do I completely reset the stack?

A: Stop the services, reset certificates, and start again:
```bash
./scripts/userver.sh stop
./scripts/userver.sh certs reset --yes
./scripts/userver.sh setup
./scripts/userver.sh start --build
```

If you encounter issues not covered in this guide, please [open an issue](https://github.com/ferdn4ndo/userver-web/issues) on the GitHub repository.
