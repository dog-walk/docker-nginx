# Set initial image
FROM alpine:edge

# Set maintainer and image info
LABEL Description="This image runs Nginx based web proxy" \
      Vendor="CodedRed" \
      Version="2.0" \
      Maintainer="Konstantin Kozhin <konstantin@codedred.com>"

# Set env variables
ENV NGINX_VERSION="1.14.0-r0"

# Install package
RUN apk add --update --no-cache certbot nginx=$NGINX_VERSION

# Create necessary folders
RUN mkdir -p /run/nginx && \
    mkdir -p /tmp/nginx && \
    mkdir -p /etc/nginx/conf

# Copy configuration files for Nginx
COPY nginx.conf /etc/nginx/

# Send request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

# Share volume for sites configurations
VOLUME [ "/etc/nginx/conf/sites", "/etc/nginx/conf/ssl", "/etc/letsencrypt" ]

# Set ports to listen
EXPOSE 80 443

# Stop signal for container
STOPSIGNAL SIGTERM

# Define entrypoint for container
CMD [ "nginx", "-g", "daemon off;" ]