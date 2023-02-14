# uServer Web

Web server microservices stack based on [nginx-proxy](https://github.com/nginx-proxy/nginx-proxy) (DNS reverse proxy), [letsencrypt-nginx-proxy-companion](https://github.com/nginx-proxy/docker-letsencrypt-nginx-proxy-companion) (SSL support and auto-renewal), and a custom health monitoring system.

It's part of the [uServer](https://github.com/users/ferdn4ndo/projects/1) stack project.

## How to use it?

### 1 - Prepare the environment

Copy the environment templates:

```sh
cp letsencrypt/.env.template letsencrypt/.env
cp monitor/.env.template monitor/.env
```

Then edit them accordingly.

### 2 - Run the Application

```sh
docker-compose up --build
```
