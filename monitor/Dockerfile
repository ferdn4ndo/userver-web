FROM nginx:alpine

WORKDIR /etc/monitor

RUN apk update && apk add --no-cache docker-cli

COPY refresh.sh /etc/monitor/refresh.sh
COPY entrypoint.sh /etc/monitor/entrypoint.sh

EXPOSE 80

CMD ["/bin/sh", "/etc/monitor/entrypoint.sh"]
