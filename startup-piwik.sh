#/bin/bash

service php5-fpm start

if [ ! -z ${PIWIK_NOT_BEHIND_PROXY+x} ]
then
  echo ">> disable reverse proxy settings - connect to piwik directly"
  sed -i '1,5d' /piwik/config/config.ini.php
else
  echo ">> piwik is configured to listen behind a reverse proxy now"
fi

if [ ! -z ${PIWIK_HSTS_HEADERS_ENABLE+x} ]
then
  echo ">> HSTS Headers enabled"
  sed -i 's/#add_header Strict-Transport-Security/add_header Strict-Transport-Security/g' /etc/nginx/nginx.conf

  if [ ! -z ${PIWIK_HSTS_HEADERS_ENABLE_NO_SUBDOMAINS+x} ]
  then
    echo ">> HSTS Headers configured without includeSubdomains"
    sed -i 's/; includeSubdomains//g' /etc/nginx/nginx.conf
  fi
else
  echo ">> HSTS Headers disabled"
fi

if [ -z ${PIWIK_MYSQL_HOST+x} ]
then
  PIWIK_MYSQL_HOST=mysql
fi

if [ -z ${PIWIK_MYSQL_PORT+x} ]
then
  PIWIK_MYSQL_PORT=3306
fi

if [ -z ${PIWIK_MYSQL_DBNAME+x} ]
then
  PIWIK_MYSQL_DBNAME=piwik
fi

if [ -z ${PIWIK_MYSQL_PREFIX+x} ]
then
  PIWIK_MYSQL_PREFIX="piwik_"
fi

echo ">> set MYSQL Host: $PIWIK_MYSQL_HOST"
sed -i "s/PIWIK_MYSQL_HOST/$PIWIK_MYSQL_HOST/g" /app/piwik/config/config.ini.php

echo ">> set MYSQL Port: $PIWIK_MYSQL_PORT"
sed -i "s/PIWIK_MYSQL_PORT/$PIWIK_MYSQL_PORT/g" /app/piwik/config/config.ini.php

echo ">> set MYSQL User: <hidden>"
sed -i "s/PIWIK_MYSQL_USER/$PIWIK_MYSQL_USER/g" /app/piwik/config/config.ini.php

echo ">> set MYSQL Password: <hidden>"
sed -i "s/PIWIK_MYSQL_PASSWORD/$PIWIK_MYSQL_PASSWORD/g" /app/piwik/config/config.ini.php

echo ">> set MYSQL DB Name: $PIWIK_MYSQL_DBNAME"
sed -i "s/PIWIK_MYSQL_DBNAME/$PIWIK_MYSQL_DBNAME/g" /app/piwik/config/config.ini.php

echo ">> set MYSQL Prefix: $PIWIK_MYSQL_PREFIX"
sed -i "s/PIWIK_MYSQL_PREFIX/$PIWIK_MYSQL_PREFIX/g" /app/piwik/config/config.ini.php

echo ">> create DB(if not exist): $PIWIK_MYSQL_DBNAME"
sed -i "s/PIWIK_MYSQL_DBNAME/$PIWIK_MYSQL_DBNAME/g" /app/piwik/config/initdb.sql
sed -i "s/PIWIK_MYSQL_USER/$PIWIK_MYSQL_USER/g" /app/piwik/config/initdb.sql
sed -i "s/PIWIK_MYSQL_PASSWORD/$PIWIK_MYSQL_PASSWORD/g" /app/piwik/config/initdb.sql
mysql -uroot -p$MYSQL_ROOT_PASSWORD -h $PIWIK_MYSQL_HOST < /app/piwik/config/initdb.sql


if [ -z ${PIWIK_MYSQL_PASSWORD+x} ] || [ -z ${PIWIK_MYSQL_USER+x} ]
then
  echo ">> piwik started, initial setup needs to be done in browser!"
  echo ">> be fast! - anyone with access to your server can configure it!"
  exit 0
fi

echo 
echo ">> #####################"
echo ">> init piwik"
echo ">> #####################"
echo

nginx 2> /dev/null > /dev/null &

sleep 4

if [ `echo "SHOW TABLES FROM $PIWIK_MYSQL_DBNAME;" | mysql -h $PIWIK_MYSQL_HOST -P $PIWIK_MYSQL_PORT -u $PIWIK_MYSQL_USER -p$PIWIK_MYSQL_PASSWORD | grep "$PIWIK_MYSQL_PREFIX" | wc -l` -lt 1 ]
then
  echo ">> no DB installed, MYSQL User or Password specified - seems like the first start"
  rm /app/piwik/config/config.ini.php

  echo ">> init Piwik"
  if [ -z ${PIWIK_ADMIN+x} ]
  then
    PIWIK_ADMIN="admin"
    echo ">> piwik admin user: $PIWIK_ADMIN"
  fi
  
  if [ -z ${PIWIK_ADMIN_PASSWORD+x} ]
  then
    PIWIK_ADMIN_PASSWORD=`perl -e 'my @chars = ("A".."Z", "a".."z"); my $string; $string .= $chars[rand @chars] for 1..10; print $string;'`
    echo ">> generated piwik admin password: $PIWIK_ADMIN_PASSWORD"
  fi
  
  if [ -z ${PIWIK_SUBSCRIBE_NEWSLETTER+x} ]
  then
    PIWIK_SUBSCRIBE_NEWSLETTER=0
  fi
  
  if [ -z ${PIWIK_SUBSCRIBE_PRO_NEWSLETTER+x} ]
  then
    PIWIK_SUBSCRIBE_PRO_NEWSLETTER=0
  fi
  
  if [ -z ${PIWIK_ADMIN_MAIL+x} ]
  then
    PIWIK_ADMIN_MAIL="no@no.tld"
    PIWIK_SUBSCRIBE_NEWSLETTER=0
    PIWIK_SUBSCRIBE_PRO_NEWSLETTER=0
  fi

  if [ -z ${SITE_NAME+x} ]
  then
    SITE_NAME="My local Website"
  fi
  
  if [ -z ${SITE_URL+x} ]
  then
    SITE_URL="http://localhost"
  fi
  
  if [ -z ${SITE_TIMEZONE+x} ]
  then
    SITE_TIMEZONE="Europe/Berlin"
  fi
  
  if [ -z ${SITE_ECOMMERCE+x} ]
  then
    SITE_ECOMMERCE=0
  fi

  if [ -z ${ANONYMISE_IP+x} ]
  then
    ANONYMISE_IP=1
  fi
  
  if [ -z ${DO_NOT_TRACK+x} ]
  then
    DO_NOT_TRACK=1
  fi


  echo ">> piwik wizard: #1 open installer"
  curl http://localhost  2> /dev/null | grep " % Done"
  sleep 5
  
  echo ">> piwik wizard: #2 open system check"
  curl http://localhost/index.php?action=systemCheck 2> /dev/null | grep " % Done"
  sleep 5
  
  echo ">> piwik wizard: #3 open database settings"
  curl http://localhost/index.php?action=databaseSetup 2> /dev/null | grep " % Done"
  sleep 5
 
  echo ">> piwik wizard: #4 store database settings"
  curl -include --form host=$PIWIK_MYSQL_HOST:$PIWIK_MYSQL_PORT --form username=$PIWIK_MYSQL_USER --form password=$PIWIK_MYSQL_PASSWORD --form dbname=$PIWIK_MYSQL_DBNAME --form tables_prefix=$PIWIK_MYSQL_PREFIX --form adapter="PDO\MYSQL" --form submit=Next+%C2%BB http://localhost/index.php?action=databaseSetup 2> /dev/null | grep " % Done"
  curl http://localhost/index.php?action=tablesCreation&module=Installation 2> /dev/null | grep " % Done"
  sleep 5
  
  echo ">> piwik wizard: #5 open piwik settings"
  curl http://localhost/index.php?action=setupSuperUser&module=Installation 2> /dev/null | grep " % Done"
  sleep 5
  
  echo ">> piwik wizard: #6 store piwik settings"
  curl --form login=$PIWIK_ADMIN --form password=$PIWIK_ADMIN_PASSWORD --form password_bis=$PIWIK_ADMIN_PASSWORD --form email=$PIWIK_ADMIN_PASSWORD  --form subscribe_newsletter_piwikorg=$PIWIK_SUBSCRIBE_NEWSLETTER  --form subscribe_newsletter_piwikpro=$PIWIK_SUBSCRIBE_PRO_NEWSLETTER --form submit=Next+%C2%BB http://localhost/index.php?action=setupSuperUser&module=Installation
  curl http://localhost/index.php?action=firstWebsiteSetup&module=Installation 2> /dev/null | grep " % Done"
  sleep 5
  
  echo ">> piwik wizard: #7 store piwik site settings"
  curl --form siteName=$SITE_NAME --form url=$SITE_URL --form timezone=$SITE_TIMEZONE --form ecommerce=$SITE_ECOMMERCE --form submit=Next+%C2%BB http://localhost/index.php?action=firstWebsiteSetup&module=Installation 2> /dev/null | grep " % Done"
  curl http://localhost/index.php?action=trackingCode&module=Installation&site_idSite=1&site_name=default 2> /dev/null | grep " % Done"
  sleep 5
  
  echo ">> piwik wizard: #8 skip js page"
  curl http://localhost/index.php?action=finished&module=Installation&site_idSite=1&site_name=default 2> /dev/null | grep " % Done"
  sleep 5

  echo ">> piwik wizard: #9 final settings"
  curl --form do_not_track=$DO_NOT_TRACK --form anonymise_ip=$ANONYMISE_IP  --form submit=Next+%C2%BB http://localhost/index.php?action=finished&module=Installation&site_idSite=1&site_name=default 2> /dev/null | grep " % Done"
  curl http://localhost/index.php 2> /dev/null | grep " % Done"
  sleep 5
 
 else
    echo ">> Piwik tabled detected, skipping setup" 
fi

echo ">> update CorePlugins"
curl http://localhost/index.php?updateCorePlugins=1 2> /dev/null | grep " % Done"

  
