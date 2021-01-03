FROM php:7.4-apache

# update apt
RUN apt-get update -yqq

# install some libs
RUN apt-get install -yqq sudo git zip unzip libzip-dev libpq-dev libjpeg-dev libpng-dev mariadb-client curl libcurl4-gnutls-dev libfreetype6-dev libicu-dev libxml2-dev libonig-dev libsodium-dev

# install some php extensions
RUN docker-php-ext-configure gd --with-jpeg=/usr/include/ --with-freetype=/usr/include/
RUN docker-php-ext-install mbstring pdo pdo_mysql pdo_pgsql curl json intl gd xml zip opcache sodium
RUN pecl install -o -f redis && rm -rf /tmp/pear && docker-php-ext-enable redis

# install composer 2
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php -r "if (hash_file('sha384', 'composer-setup.php') === '756890a4488ce9024fc62c56153228907f1545c228516cbf63f885e036d37e9a59d27d63f46af1d4d07ee0f76181c7d3') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
RUN php composer-setup.php
RUN php -r "unlink('composer-setup.php');"
RUN mv composer.phar /usr/local/bin/composer

# increase php mem limits
RUN printf "memory_limit = 768M\nupload_max_filesize = 10M\npost_max_size = 10M\n" > /usr/local/etc/php/conf.d/extra-mem.ini

# install mariadb 10.3 with rootpwd mariadb
RUN apt-get update -yqq
RUN apt-get -y install vim openssh-server mariadb-server-10.3
RUN ["/bin/bash", "-c", "debconf-set-selections <<< 'mariadb-server-10.3 mariadb-server/root_password password mariadb'"]
RUN ["/bin/bash", "-c", "debconf-set-selections <<< 'mariadb-server-10.3 mariadb-server/root_password_again password mariadb'"]

# change apache ports to 80->8080 and 443->8082
RUN sed -ri -e 's!80!8080!g' /etc/apache2/ports.conf
RUN sed -ri -e 's!443!8082!g' /etc/apache2/ports.conf
RUN sed -ri -e 's!:80!:8080!g' /etc/apache2/sites-enabled/000-default.conf

# change apache2 docroot
RUN sed -i 's:DocumentRoot /var/www/html:DocumentRoot /webserver/webroot/web:g' /etc/apache2/sites-enabled/000-default.conf
RUN { \
		echo '<Directory /webserver/webroot/>'; \
		echo '	Options Indexes FollowSymLinks'; \
		echo '	AllowOverride All'; \
		echo '	Require all granted'; \
		echo '</Directory>'; \
	} >> /etc/apache2/apache2.conf

# activate modrewrite
RUN a2enmod rewrite

# add pdo socket
RUN echo pdo_mysql.default_socket=/var/run/mysqld/mysqld.sock >> /usr/local/etc/php/conf.d/docker-php-ext-pdo_mysql.ini

# copy run-script
COPY d8d /usr/local/bin/
RUN mkdir -p /webserver/webroot

# allow drupal for sshd
RUN echo "AllowGroups drupal" >> /etc/ssh/sshd_config
WORKDIR /webserver/webroot
CMD ["d8d"]
