FROM php:8.1-fpm-alpine

# Install system dependencies and PHP extensions required by the application
RUN set -eux; \
    apk add --no-cache \
        bash \
        curl \
        tzdata \
        libzip-dev \
        oniguruma-dev \
        icu-data-full \
        icu-libs \
        libpng-dev \
        freetype-dev \
        libjpeg-turbo-dev \
        gmp-dev; \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-install -j"$(nproc)" \
        bcmath \
        exif \
        gd \
        gmp \
        intl \
        mysqli \
        opcache \
        pdo_mysql \
        zip

# Copy custom php.ini settings if present
COPY php.ini /usr/local/etc/php/conf.d/99-custom.ini

WORKDIR /var/www/html

COPY . /var/www/html

RUN chown -R www-data:www-data /var/www/html

CMD ["php-fpm"]
