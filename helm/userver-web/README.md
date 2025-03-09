# uServer-Web Helm Chart

This Helm chart deploys the uServer-Web stack on Kubernetes.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- PV provisioner support in the underlying infrastructure (if persistence is enabled)
- Ingress controller (if ingress is enabled)

## Installing the Chart

To install the chart with the release name `my-release`:

```bash
helm install my-release ./helm/userver-web
```

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```bash
helm uninstall my-release
```

## Parameters

### Global Parameters

| Name                           | Description                                      | Value           |
| ------------------------------ | ------------------------------------------------ | --------------- |
| `global.domain.base`           | Base domain for all services                     | `example.com`   |
| `global.domain.monitor`        | Subdomain for monitor service                    | `monitor`       |
| `global.domain.whoami`         | Subdomain for whoami service                     | `whoami`        |
| `global.tls.enabled`           | Enable TLS                                       | `true`          |
| `global.tls.certManager.enabled` | Use cert-manager for TLS certificates          | `true`          |
| `global.tls.certManager.issuer` | Issuer to use for certificates                  | `letsencrypt-prod` |
| `global.tls.secretName`        | Secret name for TLS certificates                 | `""`            |

### Nginx Proxy Parameters

| Name                           | Description                                      | Value           |
| ------------------------------ | ------------------------------------------------ | --------------- |
| `nginxProxy.enabled`           | Enable nginx-proxy                               | `true`          |
| `nginxProxy.image.repository`  | Nginx proxy image repository                     | `nginxproxy/nginx-proxy` |
| `nginxProxy.image.tag`         | Nginx proxy image tag                            | `1.5-alpine`    |
| `nginxProxy.image.pullPolicy`  | Nginx proxy image pull policy                    | `IfNotPresent`  |
| `nginxProxy.service.type`      | Nginx proxy service type                         | `LoadBalancer`  |
| `nginxProxy.service.port`      | Nginx proxy HTTP port                            | `80`            |
| `nginxProxy.service.httpsPort` | Nginx proxy HTTPS port                           | `443`           |
| `nginxProxy.config.clientMaxBodySize` | Nginx client max body size                | `1g`            |
| `nginxProxy.persistence.enabled` | Enable persistence for nginx-proxy             | `true`          |
| `nginxProxy.persistence.size`  | Nginx proxy PVC size                             | `1Gi`           |
| `nginxProxy.persistence.storageClass` | Nginx proxy PVC storage class             | `""`            |
| `nginxProxy.persistence.accessMode` | Nginx proxy PVC access mode                 | `ReadWriteOnce` |

### Let's Encrypt Parameters

| Name                           | Description                                      | Value           |
| ------------------------------ | ------------------------------------------------ | --------------- |
| `letsencrypt.enabled`          | Enable letsencrypt                               | `true`          |
| `letsencrypt.image.repository` | Let's Encrypt image repository                   | `nginxproxy/acme-companion` |
| `letsencrypt.image.tag`        | Let's Encrypt image tag                          | `2.3`           |
| `letsencrypt.image.pullPolicy` | Let's Encrypt image pull policy                  | `IfNotPresent`  |
| `letsencrypt.config.email`     | Email for Let's Encrypt certificates             | `admin@example.com` |
| `letsencrypt.persistence.enabled` | Enable persistence for Let's Encrypt          | `true`          |
| `letsencrypt.persistence.size` | Let's Encrypt PVC size                           | `1Gi`           |
| `letsencrypt.persistence.storageClass` | Let's Encrypt PVC storage class          | `""`            |
| `letsencrypt.persistence.accessMode` | Let's Encrypt PVC access mode              | `ReadWriteOnce` |

### Monitor Parameters

| Name                           | Description                                      | Value           |
| ------------------------------ | ------------------------------------------------ | --------------- |
| `monitor.enabled`              | Enable monitor                                   | `true`          |
| `monitor.image.repository`     | Monitor image repository                         | `ferdn4ndo/docker-containers-monitor` |
| `monitor.image.tag`            | Monitor image tag                                | `1.0.1`         |
| `monitor.image.pullPolicy`     | Monitor image pull policy                        | `IfNotPresent`  |
| `monitor.config.refreshEverySeconds` | Refresh interval in seconds                | `5`             |
| `monitor.config.statsFile`     | Path to stats file                               | `/usr/share/nginx/html/stats.txt` |
| `monitor.config.fifoPath`      | Path to FIFO pipe                                | `/tmp/userver_monitor` |

### Whoami Parameters

| Name                           | Description                                      | Value           |
| ------------------------------ | ------------------------------------------------ | --------------- |
| `whoami.enabled`               | Enable whoami                                    | `true`          |
| `whoami.image.repository`      | Whoami image repository                          | `traefik/whoami` |
| `whoami.image.tag`             | Whoami image tag                                 | `v1.10`         |
| `whoami.image.pullPolicy`      | Whoami image pull policy                         | `IfNotPresent`  |
| `whoami.service.port`          | Whoami service port                              | `80`            |

### Ingress Parameters

| Name                           | Description                                      | Value           |
| ------------------------------ | ------------------------------------------------ | --------------- |
| `ingress.enabled`              | Enable ingress                                   | `false`         |
| `ingress.className`            | Ingress class name                               | `nginx`         |
| `ingress.annotations`          | Ingress annotations                              | `{}`            |
| `ingress.hosts`                | Ingress hosts                                    | `[]`            |
| `ingress.tls`                  | Ingress TLS configuration                        | `[]`            |

### Other Parameters

| Name                           | Description                                      | Value           |
| ------------------------------ | ------------------------------------------------ | --------------- |
| `serviceAccount.create`        | Create service account                           | `true`          |
| `serviceAccount.annotations`   | Service account annotations                      | `{}`            |
| `serviceAccount.name`          | Service account name                             | `""`            |
| `podSecurityContext`           | Pod security context                             | `{}`            |
| `securityContext`              | Container security context                       | `{}`            |
| `nodeSelector`                 | Node selector                                    | `{}`            |
| `tolerations`                  | Tolerations                                      | `[]`            |
| `affinity`                     | Affinity                                         | `{}`            |

## Examples

### Using with Ingress Controller

```yaml
# values.yaml
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

ingress:
  enabled: true
  className: "nginx"
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
```

### Using with External Load Balancer

```yaml
# values.yaml
nginxProxy:
  service:
    type: LoadBalancer
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-type: nlb
```

### Using with Persistent Storage

```yaml
# values.yaml
nginxProxy:
  persistence:
    enabled: true
    storageClass: "standard"
    size: "10Gi"

letsencrypt:
  persistence:
    enabled: true
    storageClass: "standard"
    size: "5Gi"
