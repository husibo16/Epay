FROM nginx:1.25-alpine

COPY docker/nginx/default.conf /etc/nginx/conf.d/default.conf

WORKDIR /var/www/html

COPY . /var/www/html

RUN chown -R nginx:nginx /var/www/html
