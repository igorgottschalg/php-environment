FROM ubuntu:bionic

ENV DEBIAN_FRONTEND noninteractive
ENV RG_WAN_PORT 2408
ENV RG_LOG_LEVEL 0
ENV RG_ACT_TOKEN ""
ENV RG_ACT_HOST ""
ENV RG_MEMCACHED_SERVERS "memcached:11211"

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
    supervisor

ARG MAKE_J=4
ARG NGINX_VERSION=1.14.0
ARG PAGESPEED_VERSION=1.13.35.2
ARG LIBPNG_VERSION=1.6.29

ENV php_conf /etc/php/7.2/apache2/php.ini

RUN apt install -y -q apache2 \
    apache2-utils \
    libexpat1 

RUN wget https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-stable_current_amd64.deb
RUN dpkg -i mod-pagespeed-*.deb
RUN apt -f install

RUN a2enmod proxy
RUN a2enmod proxy_http
RUN a2enmod proxy_ajp
RUN a2enmod rewrite
RUN a2enmod deflate
RUN a2enmod headers
RUN a2enmod proxy_balancer
RUN a2enmod proxy_connect
RUN a2enmod proxy_html

RUN apt install -q -y \
    php \
    libapache2-mod-php7.2 \
    php7.2-soap \
    php7.2-json \
    php-pear \
    php7.2-dev \
    php7.2-zip \
    php7.2-curl \
    php7.2-gd \
    php7.2-mysql \
    php7.2-xml \
    php7.2-memcached \
    libapache2-mod-php7.2 \
    php7.2-mbstring \
    graphicsmagick \
    imagemagick \
    ca-certificates

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

RUN touch /var/log/cron.log

RUN mkdir -p /bin/autostart
ADD ./autostart.sh /bin/autostart/autostart.sh
ADD ./supervisord.conf /etc/supervisord.conf

RUN chmod +x /bin/autostart/autostart.sh

RUN curl -L  https://br.wordpress.org/wordpress-5.2.1-pt_BR.tar.gz | tar -xz -C /var/www/html
RUN mv /var/www/html/wordpress/* /var/www/html/
RUN rm -Rf /var/www/html/wordpress
RUN chmod -R g+rw /var/www && chown -R www-data:www-data /var/www

EXPOSE 443 80

HEALTHCHECK --interval=5s --timeout=3s --retries=3 CMD curl -f http://localhost || exit 1
CMD ["/bin/autostart/autostart.sh"]