FROM php:7.2-fpm

RUN apt-get update
RUN apt-get install -y \
    libmcrypt-dev \
    libicu-dev \
    libpq-dev \
    libbz2-dev \
    procps \
    mc \
    nano \
    wget \
    cron \
    supervisor \
    libevent-dev \
    librabbitmq-dev \
    # nginx \
    curl \
    libxml2 \
    libwebp-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libxpm-dev \
    libfreetype6-dev \
    libxml2-dev

RUN  docker-php-ext-install bcmath \
    && docker-php-ext-install bz2 \
    && docker-php-ext-install fileinfo \
    && docker-php-ext-install iconv \
    && docker-php-ext-install json\
    && docker-php-ext-install mbstring\
    && docker-php-ext-install mysqli\
    && docker-php-ext-install opcache

# RUN docker-php-ext-install -j$(nproc) mcrypt \
RUN  docker-php-ext-install -j$(nproc) pdo \
    && docker-php-ext-install -j$(nproc) pdo_mysql \
    && docker-php-ext-install -j$(nproc) session \
    && docker-php-ext-install -j$(nproc) simplexml \
    && docker-php-ext-install -j$(nproc) xml \
    && docker-php-ext-install -j$(nproc) zip


RUN docker-php-ext-configure gd --with-gd --with-webp-dir --with-jpeg-dir \
    --with-png-dir --with-zlib-dir --with-xpm-dir --with-freetype-dir \
    --enable-gd-native-ttf
RUN docker-php-ext-install gd

# =========>

# Install APCu and APC backward compatibility
RUN pecl install apcu \
    && pecl install apcu_bc-1.0.3 \
    && docker-php-ext-enable apcu --ini-name 10-docker-php-ext-apcu.ini \
    && docker-php-ext-enable apc --ini-name 20-docker-php-ext-apc.ini

RUN apt-get install build-essential libpcre3 libpcre3-dev openssl uuid-dev libssl-dev libperl-dev -y
RUN apt-get install git -y

ARG MAKE_J=4
ARG NGINX_VERSION=1.14.0
ARG PAGESPEED_VERSION=1.13.35.2
ARG LIBPNG_VERSION=1.6.29

ENV MAKE_J=${MAKE_J} \
    NGINX_VERSION=${NGINX_VERSION} \
    LIBPNG_VERSION=${LIBPNG_VERSION} \
    PAGESPEED_VERSION=${PAGESPEED_VERSION}

RUN cd /tmp && \
    curl -O -L https://github.com/pagespeed/ngx_pagespeed/archive/v${PAGESPEED_VERSION}-stable.zip && \
    unzip v${PAGESPEED_VERSION}-stable.zip

RUN cd /tmp/incubator-pagespeed-ngx-${PAGESPEED_VERSION}-stable/ && \
    psol_url=https://dl.google.com/dl/page-speed/psol/${PAGESPEED_VERSION}.tar.gz && \
    [ -e scripts/format_binary_url.sh ] && psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL) && \
    echo "URL: ${psol_url}" && \
    curl -L ${psol_url} | tar -xz

# Build in additional Nginx modules
RUN cd /tmp && \
    git clone git://github.com/vozlt/nginx-module-vts.git && \
    git clone https://github.com/openresty/headers-more-nginx-module.git && \
    git clone git://github.com/yaoweibin/ngx_http_substitutions_filter_module.git

# Build Nginx with support for PageSpeed
RUN cd /tmp && \
    curl -L http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz | tar -zx && \
    cd /tmp/nginx-${NGINX_VERSION} && \
    LD_LIBRARY_PATH=/tmp/incubator-pagespeed-ngx-${PAGESPEED_VERSION}/usr/lib:/usr/lib ./configure \
    --sbin-path=/usr/sbin \
    --modules-path=/usr/lib/nginx \
    --with-http_ssl_module \
    --with-http_gzip_static_module \
    --with-file-aio \
    --with-http_v2_module \
    --with-http_realip_module \
    --with-http_sub_module \
    --with-http_gunzip_module \
    --with-http_secure_link_module \
    --with-http_stub_status_module \
    --with-threads \
    --with-stream \
    --with-stream_ssl_module \
    --without-http_autoindex_module \
    --without-http_browser_module \
    --without-http_memcached_module \
    --without-http_userid_module \
    --without-mail_pop3_module \
    --without-mail_imap_module \
    --without-mail_smtp_module \
    --without-http_split_clients_module \
    --without-http_uwsgi_module \
    --without-http_scgi_module \
    --without-http_upstream_ip_hash_module \
    --prefix=/etc/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --http-log-path=/var/log/nginx/access.log \
    --error-log-path=/var/log/nginx/error.log \
    --pid-path=/var/run/nginx.pid \
    --add-module=/tmp/nginx-module-vts \
    --add-module=/tmp/headers-more-nginx-module \
    --add-module=/tmp/ngx_http_substitutions_filter_module \
    --add-module=/tmp/incubator-pagespeed-ngx-${PAGESPEED_VERSION}-stable && \
    make install --silent

RUN rm -rf /var/lib/apt/lists/* && rm -rf /tmp/* && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    mkdir -p /var/cache/ngx_pagespeed && \
    chmod -R o+wr /var/cache/ngx_pagespeed

RUN chmod +x /usr/local/bin/*

RUN mkdir -p /etc/nginx && \
    mkdir -p /var/www/app && \
    mkdir -p /run/nginx && \
    mkdir -p /var/log/supervisor && \
    mkdir -p /etc/letsencrypt/webrootauth

# nginx site conf
RUN mkdir -p /etc/nginx/sites-available/ && \
    mkdir -p /etc/nginx/sites-enabled/ && \
    mkdir -p /etc/nginx/ssl/ && \
    rm -Rf /var/www/* && \
    mkdir /var/www/html/

RUN touch /var/log/cron.log

# Add Scripts
RUN mkdir -p /bin/autostart
ADD ./autostart.sh /bin/autostart/autostart.sh
ADD ./supervisord.conf /etc/supervisord.conf

RUN chmod +x /bin/autostart/autostart.sh

EXPOSE 443 80

CMD ["/bin/autostart/autostart.sh"]