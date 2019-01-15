FROM alpine:3.6

MAINTAINER Roman Gordeev <roma.gordeev@gmail.com>

# set up nginx and nginx-rtmp-module versions
ENV NGINX_VERSION 1.13.3
ENV NGINX_SPNEGO_VERSION master

# create required directories
RUN mkdir /src /data /static

# install base nginx dependencies openssl-dev pcre-dev zlib-dev wget build-base
RUN apk --update add openssl-dev pcre-dev zlib-dev wget build-base krb5-dev curl krb5 iputils ca-certificates

# set /src as current directory
WORKDIR /src
# get nginx source
RUN set -x \ 
  && wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
  && tar zxf nginx-${NGINX_VERSION}.tar.gz \
  && rm nginx-${NGINX_VERSION}.tar.gz \
# get nginx-spnego module source
  && wget --no-check-certificate https://github.com/stnoonan/spnego-http-auth-nginx-module/archive/${NGINX_SPNEGO_VERSION}.tar.gz \
  && tar zxf ${NGINX_SPNEGO_VERSION}.tar.gz \
  && rm ${NGINX_SPNEGO_VERSION}.tar.gz

# compile nginx with spnego module
WORKDIR /src/nginx-${NGINX_VERSION}
RUN set -x \
  && ./configure \
# add modules to build with
        --with-debug \
        --with-http_ssl_module \
        --with-http_gzip_static_module \
        --with-http_stub_status_module \
        --add-module=/src/spnego-http-auth-nginx-module-${NGINX_SPNEGO_VERSION} \
# set up base path for nginx installation and logs
        --prefix=/etc/nginx \       
        --http-log-path=/var/log/nginx/access.log \
        --error-log-path=/var/log/nginx/error.log \
        --sbin-path=/usr/local/sbin/nginx \
  && make \
  && make install \
# clean up after build
  && apk del build-base \
  && rm -rf /tmp/src \
  && rm -rf /var/cache/apk/*

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

# install nginx config 
COPY nginx.conf /etc/nginx/conf/nginx.conf

# nginx log dir
VOLUME ["/var/log/nginx"]

WORKDIR /etc/nginx

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
