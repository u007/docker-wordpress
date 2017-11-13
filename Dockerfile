FROM php:7-apache

RUN a2enmod rewrite expires

# install the PHP extensions we need
RUN apt-get update && apt-get install -y libpng12-dev libjpeg-dev && rm -rf /var/lib/apt/lists/* \
	&& docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
	&& docker-php-ext-install gd mysqli opcache
RUN apt-get install -y openssl
# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN { \
        echo 'file_uploads=On'; \
        echo 'memory_limit=128M'; \
        echo 'upload_max_filesize=24M'; \
        echo 'post_max_size=24M'; \
        echo 'max_execution_time=600'; \
    } > /usr/local/etc/php/conf.d/uploads.ini

RUN a2enmod ssl; \
    a2enmod headers; \
    echo "SSLProtocol ALL -SSLv2 -SSLv3" >> /etc/apache2/apache2.conf;\
    mkdir -p /etc/apache2/ssl

ADD 001-default-ssl.conf /etc/apache2/sites-enabled/001-default-ssl.conf

VOLUME /var/www/html

ENV WORDPRESS_VERSION 4.8
ENV DOMAIN example.com
ENV SUPPORT_EMAIL support@example.com
ENV COUNTRY SG
ENV ORGANISATION Nobody

# upstream tarballs include ./wordpress/ so this gives us /usr/src/wordpress
RUN curl -o wordpress.tar.gz -SL https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz \
	&& tar -xzf wordpress.tar.gz -C /usr/src/ \
	&& rm wordpress.tar.gz \
	&& chown -R www-data:www-data /usr/src/wordpress

COPY custom_import/* /
COPY docker-entrypoint.sh /entrypoint.sh
RUN chmod a+x /entrypoint.sh

EXPOSE 80 443

# grr, ENTRYPOINT resets CMD now
ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
