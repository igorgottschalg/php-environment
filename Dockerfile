FROM debian:stable-slim

ENV DEBIAN_FRONTEND noninteractive
ENV RG_WAN_PORT 2408
ENV RG_LOG_LEVEL 0
ENV RG_ACT_TOKEN ""
ENV RG_ACT_HOST ""
ENV php_conf /etc/php/7.4/apache2/php.ini

ARG MAKE_J=4
ARG LIBPNG_VERSION=1.6.29

RUN echo -e 'LANG="en_US.UTF-8"\nLANGUAGE="en_US:en"\n' > /etc/default/locale

RUN apt update && apt -y install wget lsb-release apt-transport-https ca-certificates && \
    wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg && \
    echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list && \
    apt update

RUN apt install -q -y nano \
    curl \
    iputils-ping \
    zlibc \
    zlib1g \
    zlib1g-dev \
    zip \
    unzip \
    build-essential \
    libpcre3 \
    libpcre3-dev \
    openssl \
    uuid-dev \
    libssl-dev \
    libperl-dev \
    procps \
    mc \
    cron \
    supervisor \
    apache2 \
    apache2-utils \
    apache2-dev \
    libexpat1 \
    brotli \
    php7.4 \
    php7.4-bcmath \
    php7.4-bz2 \
    php7.4-common \
    php7.4-xmlrpc \
    php7.4-imagick \
    php7.4-cli \
    php7.4-imap \
    php7.4-opcache \
    php7.4-intl \
    php7.4-soap \
    php7.4-json \
    php7.4-dev \
    php7.4-zip \
    php7.4-curl \
    php7.4-gd \
    php7.4-mysql \
    php7.4-xml \
    php7.4-mbstring \
    php7.4-tidy \
    php7.4-ssh2 \
    libapache2-mod-php7.4 \
    php-pear \
    graphicsmagick \
    imagemagick \
    php-redis


RUN sed -i "s/memory_limit\s*=\s*.*/memory_limit = 1024M/g" ${php_conf} \
    && sed -i "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" ${php_conf} \
    && sed -i "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" ${php_conf} \
    && sed -i "s/max_execution_time\s*=\s*60/max_execution_time = 3600/g" ${php_conf} \
    && sed -i "s/variables_order = \"GPCS\"/variables_order = \"EGPCS\"/g" ${php_conf} \
    && sed -i "s/;daemonize\s*=\s*yes/daemonize = no/g" ${php_conf}

RUN wget https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-stable_current_amd64.deb && dpkg -i mod-pagespeed-*.deb && apt -f install && rm mod-pagespeed-stable_current_amd64.deb

RUN a2enmod proxy && \
    a2dismod ssl && \
    a2enmod proxy_http && \
    a2enmod proxy_ajp && \
    a2enmod rewrite && \
    a2enmod deflate && \
    a2enmod headers && \
    a2enmod proxy_balancer && \
    a2enmod proxy_connect && \
    a2enmod proxy_html && \
    a2enmod http2 && \
    a2enmod filter && \
    a2enmod speling && \
    a2enmod substitute && \
    a2enmod brotli && \
    a2enmod expires

RUN apt autoremove -y && apt clean && rm -rf /tmp/* && \
    rm -Rf /var/www/* && \
    rm -Rf /etc/apache2/sites-available/default-ssl.conf && \
    mkdir -p /var/log/supervisor && \
    mkdir -p /usr/bin && \
    mkdir -p /var/www/html && \
    mkdir -p /bin/autostart && \
    chown www-data:www-data -R /var/www* && \
    touch /var/log/cron.log && \
    touch /var/www/html/heartbeat.html

COPY config/supervisord.conf /etc/supervisor/conf.d/default.conf
COPY config/PageSpeed.conf   /etc/apache2/mods-available/pagespeed.conf
COPY config/Apache.conf      /etc/apache2/apache2.conf

WORKDIR /var/www/html

EXPOSE 443 80
HEALTHCHECK --interval=5s --timeout=3s --retries=3 CMD curl -f http://localhost/heartbeat.html || exit 1
CMD ["/bin/sh", "-c", "/usr/bin/supervisord -n"]