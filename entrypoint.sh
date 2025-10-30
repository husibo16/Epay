#!/usr/bin/env sh
set -eu

umask 0027

# Ensure the application directory is owned by the web user
chown -R www-data:www-data /var/www/html

if [ "${APP_ROLE}" = "scheduler" ]; then
  echo "Starting scheduler with supercronic"
  exec supercronic /etc/supercronic/cron
fi

if [ "${1:-}" = "php-fpm" ]; then
  exec "$@"
fi

exec "$@"
