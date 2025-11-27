FROM webdevops/php-nginx:8.2-alpine

RUN apk add --no-cache \
  nano

RUN rm -rf /opt/docker/etc/supervisor.d
COPY ./docker/supervisor.d /opt/docker/etc/supervisor.d

COPY ./docker/php-fpm/php.ini /opt/docker/etc/php/php.ini
COPY ./docker/php-fpm/application.conf /opt/docker/etc/php/fpm/pool.d/application.conf
COPY ./docker/nginx/vhost.conf /opt/docker/etc/nginx/vhost.conf
COPY ./docker/nginx/conf.d /etc/nginx/conf.d
COPY ./docker/crontab/root /etc/crontabs/root
COPY --chown=application ./moodle /var/www/html