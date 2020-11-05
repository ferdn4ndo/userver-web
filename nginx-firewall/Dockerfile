FROM bunkerity/bunkerized-nginx

# Add your own script to be executed on startup
COPY ./custom-entrypoint.sh /entrypoint.d/custom-entrypoint.sh
RUN chmod +x /entrypoint.d/custom-entrypoint.sh

# Edit default settings
# ENV MAX_CLIENT_SIZE 100m
# ENV BLOCK_TOR_EXIT_NODE no
