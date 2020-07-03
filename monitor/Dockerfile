FROM netdata/netdata:latest

ENTRYPOINT ["/usr/sbin/run.sh"]
HEALTHCHECK --interval=60s --timeout=10s --retries=3 CMD /health.sh
