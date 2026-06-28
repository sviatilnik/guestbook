FROM jenkins/jenkins:lts

USER root

# Базовые зависимости
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    sqlite3 \
    libsqlite3-dev \
    && apt-get update

# PHP 8.4 с расширениями для Symfony
RUN apt-get install -y \
    php8.4-cli \
    php8.4-mbstring \
    php8.4-xml \
    php8.4-curl \
    php8.4-mysql \
    php8.4-pgsql \
    php8.4-sqlite3 \
    php8.4-zip \
    php8.4-bcmath \
    php8.4-gd \
    php8.4-intl \
    php8.4-opcache \
    php8.4-xdebug \
    php8.4-redis \
    php8.4-amqp \
    && apt-get clean

# Настройка Xdebug
RUN echo "zend_extension=xdebug.so" > /etc/php/8.4/cli/conf.d/99-xdebug.ini \
    && echo "xdebug.mode=coverage" >> /etc/php/8.4/cli/conf.d/99-xdebug.ini \
    && echo "xdebug.start_with_request=no" >> /etc/php/8.4/cli/conf.d/99-xdebug.ini

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Symfony CLI (опционально)
RUN curl -sS https://get.symfony.com/cli/installer | bash \
    && mv /root/.symfony5/bin/symfony /usr/local/bin/symfony

USER jenkins
