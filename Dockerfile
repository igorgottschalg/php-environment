FROM php:7.4-apache

ENV php_conf /usr/local/etc/php/php.ini-production

ADD https://raw.githubusercontent.com/mlocati/docker-php-extension-installer/master/install-php-extensions /usr/local/bin/

RUN chmod uga+x /usr/local/bin/install-php-extensions && sync \
    && echo -e 'LANG="en_US.UTF-8"\nLANGUAGE="en_US:en"\n' > /etc/default/locale

RUN DEBIAN_FRONTEND=noninteractive apt-get update -q \
    && DEBIAN_FRONTEND=noninteractive apt-get install -qq -y \
      curl \
      zip \
      unzip \
      wget \
      autotools-dev \
      automake \
      libtool \
      m4 \
      git \
      brotli \
      apache2-dev\
    && install-php-extensions \
      bcmath \
      bz2 \
      gd \
      intl \
      memcached \
      memcache \
      mysqli \
      opcache \
      pdo_mysql \
      redis \
      soap \
      xsl \
      zip \
      sockets \
      apcu \
      tidy \
      ssh2

RUN sed -i "s/memory_limit\s*=\s*.*/memory_limit = 1024M/g" ${php_conf} \
    && sed -i "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" ${php_conf} \
    && sed -i "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" ${php_conf} \
    && sed -i "s/max_execution_time\s*=\s*60/max_execution_time = 3600/g" ${php_conf} \
    && sed -i "s/variables_order = \"GPCS\"/variables_order = \"EGPCS\"/g" ${php_conf} \
    && sed -i "s/;daemonize\s*=\s*yes/daemonize = no/g" ${php_conf} \
    && sed -i "s:;opcache.enable=0:opcache.enable=1:" ${php_conf} \
    && sed -i "s:;opcache.enable_cli=0:opcache.enable_cli=1:" ${php_conf} \
    && sed -i "s:;opcache.memory_consumption=64:opcache.memory_consumption=256:" ${php_conf} \
    && sed -i "s:;opcache.max_accelerated_files=2000:opcache.max_accelerated_files=1000000:" ${php_conf} \
    && sed -i "s:;opcache.validate_timestamps=1:opcache.validate_timestamps=3000:" ${php_conf} \
    && echo extension=apcu.so > ${php_conf}

RUN wget https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-stable_current_amd64.deb \
    && dpkg -i mod-pagespeed-*.deb \
    && apt -f install \
    && rm mod-pagespeed-stable_current_amd64.deb \
    && cd / \
    && git clone --depth=1 --recursive https://github.com/kjdev/apache-mod-brotli.git \
    && cd /apache-mod-brotli \
    && ./autogen.sh \
    && ./configure \
    && make \
    && install -D .libs/mod_brotli.so /usr/lib/apache2/modules/mod_brotli.so -m 644 \
    && cd /etc/apache2/mods-available && echo "LoadModule brotli_module /usr/lib/apache2/modules/mod_brotli.so" > brotli.load

RUN a2enmod proxy && \
    a2enmod ssl && \
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
    a2enmod expires && \
    a2enmod deflate

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
CMD ["apache2-foreground"]