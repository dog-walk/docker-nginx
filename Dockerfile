# Set initial image
FROM debian:latest

# Set maintainer and image info
MAINTAINER Konstantin Kozhin <konstantin@profitco.ru>
LABEL Description="This image runs Nginx based web proxy" Vendor="ProfitCo" Version="1.0"

# Install required packages
RUN apt-get update \
    && apt-get install build-essential wget curl vim openssl libssl-dev unzip sudo -y \
    && apt-get clean all

# Setup Environment
ENV SRC_PATH=/src \
    NPS_VERSION=1.12.34.2 \
    NGINX_VERSION=1.13.1

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
    && ./configure --add-module=$HOME/ngx_pagespeed-${NPS_VERSION} ${PS_NGX_EXTRA_FLAGS} \
    && make \
    && make install \
    && ln -s /opt/nginx/sbin/nginx /usr/sbin/nginx \
#    && ln -s /opt/nginx/etc /etc/nginx \
    && cd ~ \
    && rm -Rf /src/*

# Set new working dir
WORKDIR /etc/nginx

# Set ports to listen
EXPOSE 80 443

# Stop signal for container
STOPSIGNAL SIGTERM

# Define entrypoint for container
ENTRYPOINT ["nginx", "-g", "daemon off;"]
