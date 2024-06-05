# uServer Web

[![E2E test status](https://github.com/ferdn4ndo/userver-web/actions/workflows/test_ut_e2e.yml/badge.svg?branch=main)](https://github.com/ferdn4ndo/userver-web/actions)
[![GitLeaks test status](https://github.com/ferdn4ndo/userver-web/actions/workflows/test_code_leaks.yml/badge.svg?branch=main)](https://github.com/ferdn4ndo/userver-web/actions)
[![ShellCheck test status](https://github.com/ferdn4ndo/userver-web/actions/workflows/test_code_quality.yml/badge.svg?branch=main)](https://github.com/ferdn4ndo/userver-web/actions)
[![Release](https://img.shields.io/github/v/release/ferdn4ndo/userver-web)](https://github.com/ferdn4ndo/userver-web/releases)
[![MIT license](https://img.shields.io/badge/license-MIT-brightgreen.svg)](https://opensource.org/licenses/MIT)

Web server microservices stack based on [nginx-proxy](https://github.com/nginx-proxy/nginx-proxy) for DNS reverse proxy, [letsencrypt-nginx-proxy-companion](https://github.com/nginx-proxy/docker-letsencrypt-nginx-proxy-companion) for SSL support and auto-renewal, a lightweight containers resource usage monitoring by [docker-containers-monitor](https://github.com/ferdn4ndo/docker-containers-monitor), and a 'Who Am I?' container for basic health checking using [whoami](https://github.com/traefik/whoami).

It's part of the [uServer](https://github.com/users/ferdn4ndo/projects/1) stack project.

## How to use it?

### 1 - Prepare the environment

Copy the environment templates:

```sh
cp letsencrypt/.env.template letsencrypt/.env
cp monitor/.env.template monitor/.env
cp nginx-proxy/.env.template nginx-proxy/.env
cp whoami/.env.template whoami/.env
```

Then edit them accordingly. To play locally as-is, the only missing values are the hosts (`VIRTUAL_HOST`) on both `monitor/.env` and `whoami/.env` files. Remember to redirect them to `127.0.0.1` on your OS hosts file too.

Example: assume that you want to expose the `userver-monitor` container output on `monitor.userver.lan`, make sure to set `VIRTUAL_HOST=monitor.userver.lan` in the `monitor/.env` file and then run:

```bash
sudo echo "127.0.0.1 monitor.userver.lan" | sudo tee -a /etc/hosts
```

Or edit the `/etc/hosts` manually.

You will have to do the same for the `userver-whoami` domain, setting `VIRTUAL_HOST=whoami.userver.lan` in the `whoami/.env` file and then adding `whoami.userver.lan` to the OS hosts file.

### 2 - Run the Application

```sh
docker-compose up --build
```
