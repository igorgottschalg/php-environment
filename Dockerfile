FROM php:7.4-fpm-alpine

RUN \
    apk add --no-cache --virtual .persistent-deps \
        freetype-dev \
        git \
        icu-libs \
        libzip-dev \
        libjpeg-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libxml2-dev \
        libxml2-utils \
        libxslt-dev \
        openssh-client \
	    mysql-client \
        patch \
        perl \
        ssmtp \
        nodejs \
        npm \
        yarn
RUN apk add --no-cache --virtual .build-deps \
    $PHPIZE_DEPS icu-dev && \
    pecl install -f xdebug-2.9.6 && \
    pecl install apcu mcrypt-1.0.1 && \
    pecl install apcu redis

RUN docker-php-ext-configure bcmath && \
    docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install -j$(nproc) \
        sockets \
        pcntl \
        bcmath \
        intl \
        gd \
        opcache \
        pdo_mysql \
        soap \
        xsl \
	    dom \
        zip && \
    docker-php-ext-enable xdebug && \
    docker-php-ext-enable redis && \
    yarn global add grunt-cli && \
    apk del .build-deps

RUN apk add --no-cache nginx py-pip
RUN pip install supervisor

RUN mkdir -p /var/log/supervisor && \
    mkdir -p /var/www/html && \
    mkdir -p /bin/autostart && \
    chown www-data:www-data -R /var/www* && \
    touch /var/log/cron.log && \
    touch /var/www/html/heartbeat.html

ADD supervisord.conf /etc/supervisor/conf.d/default.conf

ENV COMPOSER_ALLOW_SUPERUSER 1
RUN \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    composer global require "hirak/prestissimo:dev-master" --no-suggest --optimize-autoloader --classmap-authoritative

CMD ["supervisord", "-c", "/etc/supervisor/conf.d/default.conf"]
