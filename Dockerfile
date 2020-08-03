FROM php:7.4-fpm-alpine

RUN \
    apk add --no-cache --virtual .persistent-deps \
        freetype-dev \
        git \
        icu-libs \
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
        yarn && \
        nginx && \
    apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        icu-dev && \
    docker-php-ext-configure bcmath && \
    docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ && \
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
    yes "" | pecl install apcu redis && \
    docker-php-ext-enable apcu redis && \
    pecl install apcu mcrypt-1.0.1 && \
    perl -pi -e "s/mailhub=mail/mailhub=maildev/" /etc/ssmtp/ssmtp.conf && \
    perl -pi -e "s|;pm.status_path = /status|pm.status_path = /php_fpm_status|g" /usr/local/etc/php-fpm.d/www.conf && \
    yarn global add grunt-cli && \
    apk del .build-deps && \
    apk add --no-cache --virtual .build-deps $PHPIZE_DEPS && \
    yes "" | pecl install -f xdebug-2.6.1 && \
    docker-php-ext-enable xdebug

## Install Composer globally
ENV COMPOSER_ALLOW_SUPERUSER 1
RUN \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    composer global require "hirak/prestissimo:dev-master" --no-suggest --optimize-autoloader --classmap-authoritative

CMD ["php-fpm"]
