FROM gottschalg/php-environment

RUN mkdir -p /var/www/html/loja
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN chmod +x wp-cli.phar && mv wp-cli.phar /usr/bin/wp
RUN apt install -y nodejs npm && npm -g install @gottschalg/wordpress-package

EXPOSE 443 80
CMD ["/bin/sh", "-c", "/usr/bin/supervisord -n"]