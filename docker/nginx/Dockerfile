FROM nginx:1.25-alpine

# Copy the vhost configuration from the repository root explicitly so BuildKit
# never looks for it in the image root ("/") when a different build context is
# provided.
COPY ./docker/nginx/default.conf /etc/nginx/conf.d/default.conf

WORKDIR /var/www/html

COPY . /var/www/html

RUN chown -R nginx:nginx /var/www/html
