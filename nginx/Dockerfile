FROM nginx

# Create a non-root user.
RUN useradd --user-group --system wtserver

# Change ownership so the default configuration can be modified.
RUN chown -R wtserver:wtserver /etc/nginx/conf.d

USER wtserver:wtserver
