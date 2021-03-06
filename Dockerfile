FROM ubuntu:20.04

LABEL org.opencontainers.image.ref.name="frauhottelmann/daloradius-docker" \
      org.opencontainers.image.created=$BUILD_RFC3339 \
      org.opencontainers.image.authors="frauhottelmann" \
      org.opencontainers.image.documentation="https://github.com/frauhottelmann/daloradius-docker/blob/master/README.md" \
      org.opencontainers.image.description="Docker image with freeradius, daloradius, apache2, php. You need to supply your own MariaDB-Server." \
      org.opencontainers.image.licenses="GPLv3" \
      org.opencontainers.image.source="https://github.com/frauhottelmann/daloradius-docker" \
      org.opencontainers.image.revision=$COMMIT \
      org.opencontainers.image.version=$VERSION \
      org.opencontainers.image.url="https://hub.docker.com/r/frauhottelmann/daloradius-docker"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive
ARG BUILD_RFC3339="1970-01-01T00:00:00Z"
ARG COMMIT
ARG VERSION

STOPSIGNAL SIGKILL

ENV MYSQL_USER radius
ENV MYSQL_PASSWORD dalodbpass
ENV MYSQL_HOST localhost
ENV MYSQL_PORT 3306
ENV MYSQL_DATABASE radius

ENV TZ Europe/Berlin

RUN apt-get update \
 && apt-get install --yes --no-install-recommends \
                    apt-utils \
                    tzdata \
                    apache2 \
                    libapache2-mod-php \
                    cron \
                    freeradius-config \
                    freeradius-utils \
                    freeradius \
                    freeradius-common \
                    freeradius-mysql \
                    net-tools \
                    php \
                    php-common \
                    php-gd \
                    php-curl \
                    php-mail \
                    php-mail-mime \
                    php-db \
                    php-mysql \
                    mariadb-client \
                    libmysqlclient-dev \
                    supervisor \
                    unzip \
                    wget \
 && rm -rf /var/lib/apt/lists/*
 
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
 && update-ca-certificates -f \
 && mkdir -p /tmp/pear/cache \
 && wget http://pear.php.net/go-pear.phar \
 && php go-pear.phar \
 && rm go-pear.phar \
 && pear channel-update pear.php.net \
 && pear install -a -f DB \
 && pear install -a -f Mail \
 && pear install -a -f Mail_Mime

ENV DALO_VERSION 1.1-2

RUN wget https://github.com/lirantal/daloradius/archive/"$DALO_VERSION".zip \
 && unzip "$DALO_VERSION".zip \
 && rm "$DALO_VERSION".zip \
 && mv daloradius-"$DALO_VERSION" /var/www/html/daloradius \
 && chown -R www-data:www-data /var/www/html/daloradius \
 && chmod 644 /var/www/html/daloradius/library/daloradius.conf.php

EXPOSE 1812 1813 80

COPY supervisor-apache2.conf /etc/supervisor/conf.d/apache2.conf
COPY supervisor-freeradius.conf /etc/supervisor/conf.d/freeradius.conf
COPY freeradius-default-site /etc/freeradius/3.0/sites-available/default

COPY init.sh /cbs/
COPY supervisor.conf /etc/

CMD ["sh", "/cbs/init.sh"]
