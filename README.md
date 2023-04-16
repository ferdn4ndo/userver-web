# uServer Web

Web server microservices stack based on [nginx-proxy](https://github.com/nginx-proxy/nginx-proxy) for DNS reverse proxy, [letsencrypt-nginx-proxy-companion](https://github.com/nginx-proxy/docker-letsencrypt-nginx-proxy-companion) for SSL support and auto-renewal, a lightweight containers resource usage monitoring by [docker-containers-monitor](https://github.com/ferdn4ndo/docker-containers-monitor), and a 'Who Am I?' container for basic health checking using [whoami](https://github.com/traefik/whoami).

It's part of the [uServer](https://github.com/users/ferdn4ndo/projects/1) stack project.

## How to use it?

### 1 - Prepare the environment

Copy the environment templates:

```sh
cp nginx-proxy/.env.template nginx-proxy/.env
cp letsencrypt/.env.template letsencrypt/.env
cp monitor/.env.template monitor/.env
```

Then edit them accordingly.

### 2 - Run the Application

```sh
docker-compose up --build
```
