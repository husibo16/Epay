# syntax=docker/dockerfile:1.4

FROM php:7.4-cli-alpine AS vendor

ENV COMPOSER_ALLOW_SUPERUSER=1

RUN apk add --no-cache --virtual .vendor-run-deps \
        gmp \
    && apk add --no-cache \
        git \
        unzip \
    && apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        gmp-dev \
    && docker-php-ext-install -j"$(nproc)" \
        bcmath \
        gmp \
    && apk del .build-deps

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app

# Install PHP dependencies for the application layer
COPY includes/composer.json includes/
RUN --mount=type=cache,target=/tmp/cache \
    cd includes \
    && composer install \
        --no-dev \
        --prefer-dist \
        --optimize-autoloader \
        --no-interaction \
        --no-progress

FROM php:7.4-fpm-alpine AS runtime

ENV APP_ENV=production \
    APP_ROLE=app

# System dependencies required to build PHP extensions and run the app
RUN apk add --no-cache \
        bash \
        curl \
        icu-data-full \
        icu-libs \
        freetype \
        gmp \
        libjpeg-turbo \
        libpng \
        libzip \
        oniguruma \
    && apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        freetype-dev \
        gmp-dev \
        icu-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        libzip-dev \
        oniguruma-dev \
    && docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" \
        bcmath \
        gd \
        gmp \
        intl \
        opcache \
        pdo_mysql \
        zip \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del .build-deps

# Install supercronic for running scheduled jobs in a dedicated container
RUN curl -fsSL https://github.com/aptible/supercronic/releases/download/v0.2.24/supercronic-linux-amd64 \
        -o /usr/local/bin/supercronic \
    && chmod +x /usr/local/bin/supercronic

WORKDIR /var/www/html

# Copy application source
COPY . /var/www/html
COPY --from=vendor /app/includes/vendor /var/www/html/includes/vendor

# Provide runtime configuration
COPY php.ini /usr/local/etc/php/conf.d/zz-app.ini
COPY scheduler.cron /etc/supercronic/cron
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh \
    && chown -R www-data:www-data /var/www/html \
    && mkdir -p /var/log/php \
    && touch /var/log/php/error.log \
    && chown -R www-data:www-data /var/log/php

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=5 \
    CMD php -r "exit(extension_loaded('pdo_mysql') ? 0 : 1);"

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm"]