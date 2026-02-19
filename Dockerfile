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

EXPOSE 8000

CMD ["bash", "-lc", "git config --global --add safe.directory /var/www/html || true && if [ ! -f .env ]; then cp .env.example .env; fi && composer install --no-interaction --prefer-dist && npm install && if ! grep -q '^APP_KEY=base64:' .env; then php artisan key:generate --force; fi && php artisan storage:link || true && php artisan serve --host=0.0.0.0 --port=8000"]
