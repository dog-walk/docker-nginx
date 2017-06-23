# Set initial image
FROM debian:latest

# Set maintainer and image info
MAINTAINER Konstantin Kozhin <konstantin@profitco.ru>
LABEL Description="This image runs Nginx based web proxy" Vendor="ProfitCo" Version="1.0"

# Install required packages
RUN apt-get update \
    && apt-get install build-essential wget curl vim openssl libssl-dev zlib1g-dev libpcre3 libpcre3-dev unzip sudo -y \
    && apt-get clean all

# Setup Environment
ENV SRC_PATH=/src \
    NPS_VERSION=1.12.34.2 \
    NGINX_VERSION=1.13.1 \
    NGINX_PATH=/usr/local/nginx

# Use SRC_PATH as a working dir
WORKDIR $SRC_PATH

# Download and install Google PageSpeed module for Nginx
RUN wget https://github.com/pagespeed/ngx_pagespeed/archive/v${NPS_VERSION}-beta.zip \
    && unzip v${NPS_VERSION}-beta.zip \
    && rm v${NPS_VERSION}-beta.zip \
    && cd ngx_pagespeed-${NPS_VERSION}-beta/ \
    && PSOL_URL=https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz \
    && [ -e scripts/format_binary_url.sh ] && PSOL_URL=$(scripts/format_binary_url.sh PSOL_BINARY_URL) \
    && wget ${PSOL_URL} \
    && tar -xzvf $(basename ${PSOL_URL})

# Download and install Nginx web-server
RUN wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
    && tar -xzf nginx-${NGINX_VERSION}.tar.gz \
    && cd nginx-${NGINX_VERSION}/ \
    && ./configure --add-module=$SRC_PATH/ngx_pagespeed-${NPS_VERSION}-beta ${PS_NGX_EXTRA_FLAGS} \
    && make \
    && make install \
    && ln -s $NGINX_PATH/sbin/nginx /usr/sbin/nginx \
    && ln -s $NGINX_PATH /etc/nginx \
    && cd ~ \
    && rm -Rf $SRC_PATH/*

# Set new working dir
WORKDIR $NGINX_PATH

# Copy configuration files for Nginx
COPY nginx.conf ./conf/

# Send request and error logs to docker log collector
RUN ln -sf /dev/stdout $NGINX_PATH/logs/access.log \
    && ln -sf /dev/stderr $NGINX_PATH/logs/error.log

# Share volume for sites configurations
VOLUME ["/usr/local/nginx/conf/sites"]

# Set ports to listen
EXPOSE 80 443

# Stop signal for container
STOPSIGNAL SIGTERM

# Define entrypoint for container
CMD ["nginx", "-g", "daemon off;"]
