FROM webdevops/php-nginx:8.2-alpine

WORKDIR /var/www/html

# Sesuaikan UID dan GID dengan user yang digunakaan untuk menjalankan container.
ARG UID=1000
ARG GID=1000

RUN apk add --no-cache \
  nano

# Hapus user 'application' jika ada
RUN if id application >/dev/null 2>&1; then \
      userdel -r application; \
    fi

# Hapus group 'application' jika ada
RUN if getent group application >/dev/null 2>&1; then \
      groupdel application; \
    fi

# Buat group baru dengan GID yang ditentukan
RUN groupadd -g ${GID} application

# Buat user baru dengan UID dan GID yang ditentukan
RUN useradd -m -u ${UID} -g ${GID} -s /bin/bash application

RUN rm -rf /opt/docker/etc/supervisor.d
COPY ./docker/supervisor/supervisor.conf /opt/docker/etc/supervisor.conf
COPY ./docker/supervisor/conf.d /opt/docker/etc/supervisor.d

COPY ./docker/php-fpm/php.ini /opt/docker/etc/php/php.ini
COPY ./docker/php-fpm/application.conf /opt/docker/etc/php/fpm/pool.d/application.conf
COPY ./docker/nginx/vhost.conf /opt/docker/etc/nginx/vhost.conf
COPY ./docker/nginx/nginx.conf /opt/docker/etc/nginx/nginx.conf
COPY ./docker/nginx/conf.d /etc/nginx/conf.d
COPY ./docker/syslog-ng/syslog-ng.conf /opt/docker/etc/syslog-ng/syslog-ng.conf

COPY --chown=application:application ./health /var/www/health

RUN ln -sf /var/run/syslog-ng.sock /dev/log
RUN chown -R application:application /opt/docker/etc /var/lib/nginx /var/run /run /var/lib/syslog-ng

USER application
