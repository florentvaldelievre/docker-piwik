FROM ubuntu:14.10

RUN apt-get update && apt-get install -y \
    nginx \
    mysql-client \
    php5-mysql \
    php5-gd \
    php5-geoip \
    php-apc \
    php5-fpm \
    curl

RUN echo "cgi.fix_pathinfo = 0;" >> /etc/php5/fpm/php.ini

# clean http directory
RUN rm -rf /usr/share/nginx/html/*

# install nginx piwik config
ADD nginx-piwik.conf /etc/nginx/nginx.conf

ENV PIWIK_HOME /app/piwik
RUN mkdir -p $PIWIK_HOME
RUN mkdir -p $PIWIK_HOME/logs
RUN curl http://builds.piwik.org/piwik-latest.tar.gz | tar --strip-components=1 -xzf - -C $PIWIK_HOME
RUN chown -R www-data:www-data $PIWIK_HOME

# add piwik config
ADD config.ini.php $PIWIK_HOME/config/config.ini.php
ADD initdb.sql $PIWIK_HOME/config/initdb.sql

# add startup.sh
ADD startup-piwik.sh /opt/startup-piwik.sh
RUN chmod a+x /opt/startup-piwik.sh

CMD /opt/startup-piwik.sh
