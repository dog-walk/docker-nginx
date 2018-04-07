# Set initial image
FROM debian:latest

# Set maintainer and image info
LABEL Description="This image runs Nginx based web proxy" \
      Vendor="CodedRed" \
      Version="1.2" \
      Maintainer="Konstantin Kozhin <konstantin@codedred.com>"

# Install backports
RUN echo 'deb http://ftp.debian.org/debian stretch-backports main' > /etc/apt/sources.list.d/backports.list

# Install required packages
RUN apt-get update \
    && apt-get install build-essential wget curl vim openssl libssl-dev zlib1g-dev libpcre3 libpcre3-dev unzip -y \
    && apt-get install certbot -t stretch-backports -y \ 
    && apt-get clean all

# Setup Environment
ENV SRC_PATH /src
ENV NGINX_VERSION 1.13.11
ENV NGINX_PATH /usr/local/nginx

# Use SRC_PATH as a working dir
WORKDIR $SRC_PATH

# Download, build and install Nginx
RUN wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
    && tar -xzf nginx-${NGINX_VERSION}.tar.gz \
    && rm nginx-${NGINX_VERSION}.tar.gz \
    && cd nginx-${NGINX_VERSION}/ \
    && ./configure --prefix=${NGINX_PATH} \
      --with-file-aio \
      --with-http_addition_module \
      --with-http_auth_request_module \
      --with-http_dav_module \
      --with-http_flv_module \
      --with-http_gunzip_module \
      --with-http_gzip_static_module \
      --with-http_mp4_module \
      --with-http_random_index_module \
      --with-http_realip_module \
      --with-http_secure_link_module \
      --with-http_slice_module \
      --with-http_ssl_module \
      --with-http_stub_status_module \
      --with-http_sub_module \
      --with-http_v2_module \
      --with-mail \
      --with-mail_ssl_module \
      --with-stream \
      --with-stream_ssl_module \
      --with-threads \
    && make \
    && make install \
    && ln -s $NGINX_PATH/sbin/nginx /usr/sbin/nginx \
    && ln -s $NGINX_PATH /etc/nginx \
    && cd ~ \
    && rm -Rf $SRC_PATH/*

# Clean up packages
RUN apt-get remove build-essential libssl-dev zlib1g-dev libpcre3-dev unzip -y \
    && apt-get autoremove -y \
    && apt-get clean all

# Set new working dir
WORKDIR $NGINX_PATH

# Copy configuration files for Nginx
COPY nginx.conf ./conf/

# Copy sample configurations for Nginx
RUN mkdir -p ${NGINX_PATH}/conf/samples
COPY http.site.conf ./samples/
COPY https.site.conf ./samples/

# Send request and error logs to docker log collector
RUN ln -sf /dev/stdout $NGINX_PATH/logs/access.log \
    && ln -sf /dev/stderr $NGINX_PATH/logs/error.log

# Share volume for sites configurations
VOLUME ["${NGINX_PATH}/conf/sites", "${NGINX_PATH}/conf/ssl", "/etc/letsencrypt"]

# Set ports to listen
EXPOSE 80 443

# Stop signal for container
STOPSIGNAL SIGTERM

# Define entrypoint for container
CMD ["nginx", "-g", "daemon off;"]

