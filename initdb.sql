CREATE DATABASE IF NOT EXISTS PIWIK_MYSQL_DBNAME;
GRANT ALL ON `PIWIK_MYSQL_DBNAME`.* to 'PIWIK_MYSQL_USER'@'%' identified by 'PIWIK_MYSQL_PASSWORD';
FLUSH PRIVILEGES;
