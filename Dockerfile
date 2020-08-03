FROM php:7.4-fpm


ENV PHP_OPCACHE_VALIDATE_TIMESTAMPS="0" \
    PHP_OPCACHE_MAX_ACCELERATED_FILES="10000" \
    PHP_OPCACHE_MEMORY_CONSUMPTION="192" \
    PHP_OPCACHE_MAX_WASTED_PERCENTAGE="10" \
    PHP_CONFIG=/etc/php/7.4/apache2/php.ini


RUN apt-get update \
  && apt-get install -y \
    libfreetype6-dev \ 
    libicu-dev \ 
    libjpeg62-turbo-dev \ 
    libmcrypt-dev \ 
    libpng-dev \ 
    libxslt1-dev \ 
    sendmail-bin \ 
    sendmail \ 
    sudo \ 
    libzip-dev \ 
    libonig-dev \
    supervisor \
    nginx

RUN docker-php-ext-configure gd --with-freetype --with-jpeg

RUN docker-php-ext-install \
  dom \ 
  gd \ 
  intl \ 
  mbstring \ 
  pdo_mysql \ 
  xsl \ 
  zip \ 
  soap \ 
  bcmath \ 
  pcntl \ 
  sockets \
  opcache

RUN pecl install -o -f xdebug mcrypt redis

RUN docker-php-ext-enable xdebug && \
    docker-php-ext-enable redis && \
    docker-php-ext-enable mcrypt

RUN sed -i "s/memory_limit\s*=\s*.*/memory_limit = 2048M/g" ${PHP_CONFIG} \
    && sed -i "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" ${PHP_CONFIG} \
    && sed -i "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" ${PHP_CONFIG} \
    && sed -i "s/max_execution_time\s*=\s*60/max_execution_time = 3600/g" ${PHP_CONFIG} \
    && sed -i "s/variables_order = \"GPCS\"/variables_order = \"EGPCS\"/g" ${PHP_CONFIG} \
    && sed -i "s/;daemonize\s*=\s*yes/daemonize = no/g" ${PHP_CONFIG}

RUN mkdir -p /var/log/supervisor && \
    mkdir -p /var/www/html && \
    mkdir -p /bin/autostart && \
    chown www-data:www-data -R /var/www* && \
    touch /var/log/cron.log 

ADD ./configs/supervisord.conf /etc/supervisor/conf.d/default.conf
ADD ./configs/nginx.conf /etc/nginx/nginx.conf
ADD ./configs/opcache.ini /usr/local/etc/php.d/opcache.ini

ENV COMPOSER_ALLOW_SUPERUSER 1
RUN \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    composer global require "hirak/prestissimo:dev-master" --no-suggest --optimize-autoloader --classmap-authoritative

CMD ["/bin/sh", "-c", "/usr/bin/supervisord -n"]
