FROM php:8.4-cli

WORKDIR /var/www/html

RUN apt-get update && apt-get install -y \
    git \
    unzip \
    curl \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libzip-dev \
    libicu-dev \
    libxml2-dev \
    libonig-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    default-mysql-client \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) pdo_mysql bcmath gd intl zip exif pcntl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get update && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY . .

RUN git config --global --add safe.directory /var/www/html \
    && mkdir -p bootstrap/cache \
    && mkdir -p storage/logs \
    && mkdir -p storage/framework/cache/data \
    && mkdir -p storage/framework/sessions \
    && mkdir -p storage/framework/views \
    && chmod -R 775 storage bootstrap/cache \
    && (chmod 664 .env || true) \
    && (chmod 664 config/system-addons.php || true) \
    && (chmod 664 app/Providers/RouteServiceProvider.php || true) \
    && composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader \
    && npm ci \
    && npm run prod \
    && rm -rf node_modules \
    && rm -f bootstrap/cache/*.php

EXPOSE 8080

CMD ["bash", "-lc", "mkdir -p storage/logs storage/framework/cache/data storage/framework/sessions storage/framework/views bootstrap/cache && chmod -R 775 storage bootstrap/cache && touch .env && chmod 664 .env config/system-addons.php app/Providers/RouteServiceProvider.php || true && php artisan optimize:clear || true && php artisan storage:link || true && php artisan serve --host=0.0.0.0 --port=${PORT:-8080}"]
