FROM debian:stable-slim

ENV DEBIAN_FRONTEND noninteractive
ENV RG_WAN_PORT 2408
ENV RG_LOG_LEVEL 0
ENV RG_ACT_TOKEN ""
ENV RG_ACT_HOST ""
ENV RG_MEMCACHED_SERVERS "memcached:11211"
ENV php_conf /etc/php/7.4/apache2/php.ini

ARG MAKE_J=4
ARG LIBPNG_VERSION=1.6.29

RUN echo -e 'LANG="en_US.UTF-8"\nLANGUAGE="en_US:en"\n' > /etc/default/locale

RUN apt update
RUN apt list --upgradable
RUN apt update

RUN apt install -q -y nano \
    curl \
    git \
    wget \
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
    memcached

RUN apt install -y -q apache2 \
    apache2-utils \
    apache2-dev \
    libexpat1 \
    brotli

RUN wget https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-stable_current_amd64.deb
RUN dpkg -i mod-pagespeed-*.deb
RUN apt -f install

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

RUN apt -y install lsb-release apt-transport-https ca-certificates
RUN wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
RUN echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list
RUN apt update

RUN apt install -q -y php7.4
RUN apt install -q -y \
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
    php7.4-memcached \
    php7.4-mbstring \
    php7.4-tidy \
    php7.4-ssh2

RUN apt install -q -y libapache2-mod-php7.4 php-pear graphicsmagick imagemagick php-redis php-memcached
RUN phpenmod memcached

RUN sed -i "s/memory_limit\s*=\s*.*/memory_limit = 1024M/g" ${php_conf} \
    && sed -i "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" ${php_conf} \
    && sed -i "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" ${php_conf} \
    && sed -i "s/max_execution_time\s*=\s*60/max_execution_time = 3600/g" ${php_conf} \
    && sed -i "s/variables_order = \"GPCS\"/variables_order = \"EGPCS\"/g" ${php_conf} \
    && sed -i "s/;daemonize\s*=\s*yes/daemonize = no/g" ${php_conf}

RUN apt autoremove -y && apt clean && rm -rf /var/lib/apt/lists/* && rm -rf /tmp/*

RUN mkdir -p /var/log/supervisor && \
    mkdir -p /etc/letsencrypt/webrootauth

RUN mkdir -p /usr/bin/ && \
    rm -Rf /var/www/* && \
    mkdir /var/www/html/

RUN chown www-data:www-data  -R /var/www*

RUN touch /var/log/cron.log
RUN mkdir -p /bin/autostart

ADD supervisord.conf /etc/supervisor/conf.d/default.conf
RUN touch /var/www/html/heartbeat.html

WORKDIR /var/www/html

EXPOSE 443 80
HEALTHCHECK --interval=5s --timeout=3s --retries=3 CMD curl -f http://localhost/heartbeat.html || exit 1
CMD ["/bin/sh", "-c", "/usr/bin/supervisord -n"]