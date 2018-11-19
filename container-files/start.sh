#!/bin/sh
rm -rf /etc/localtime
ln -s  /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
source /etc/sysconfig/i18n
\cp -rf /bash/cacti.conf /etc/httpd/conf.d/cacti.conf
\cp -rf /bash/httpd.conf /etc/httpd/conf/httpd.conf
\cp -rf /bash/php.ini /etc/php.ini
\cp -rf /bash/rsyslog.conf /etc/rsyslog.conf
\cp -rf /bash/config.php /var/www/html/include/config.php
\cp -rf /bash/global.php /var/www/html/include/global.php
\cp -rf /bash/spine.conf /etc/spine.conf
\cp -rf /bash/i18n /etc/sysconfig/i18n
mkdir -p /var/www/bash/ 
\cp -rf /bash/export.sh /var/www/bash/export.sh
\cp -rf /bash/backup.sh /var/www/bash/backup.sh
\cp -rf /bash/cacti /etc/cron.d/cacti
chown -R apache:apache /var/www 
chmod 644 /etc/cron.d/cacti 

du -ah  /var/www
du -ah /cacti
create_db(){
    echo "Creating Cacti Database"
	mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "set collation_server = utf8mb4_unicode_ci;"
	mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "set character_set_client = utf8mb4;"
	mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "CREATE DATABASE  IF NOT EXISTS cacti DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
	mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "grant all on cacti.* to '${DB_USER}'@'localhost' identified by '${DB_PASSWORD}'"
	mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "grant select on mysql.time_zone_name to '${DB_USER}'@'localhost' identified by '${DB_PASSWORD}'"
	mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "flush privileges;"
	mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e 'create database `syslog` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;'
	mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "GRANT ALL ON syslog.* TO 'cactiuser'@localhost IDENTIFIED BY 'cactiuser';"
	mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e 'flush privileges;'
    echo "Database created successfully"
}
import_db() {
    echo "Importing Database..."
	mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} cacti < /var/www/html/cacti.sql
	mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "INSERT INTO cacti.settings (name, value) VALUES ('font_method', '0');"
	mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "INSERT INTO cacti.settings (name, value) VALUES ('max_title_data_source', '150');"
	mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "INSERT INTO cacti.settings (name, value) VALUES ('poller_type', '2');"
	mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "INSERT INTO cacti.settings (name, value) VALUES ('plugin_watermark_text', '$rrdlogo');"
	mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "INSERT INTO cacti.settings (name, value) VALUES ('num_rows_device', '100');"
	mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "INSERT INTO cacti.settings (name, value) VALUES ('num_rows_data_query', '100');"
	mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "INSERT INTO cacti.settings (name, value) VALUES ('num_rows_data_source', '100');"
	mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "INSERT INTO cacti.settings (name, value) VALUES ('num_rows_graph', '250');"
	mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "INSERT INTO cacti.settings (name, value) VALUES ('max_title_graph ', '100');"
	mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "INSERT INTO cacti.settings (name, value) VALUES ('max_data_query_field_length', '100');"
	mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "INSERT INTO cacti.settings (name, value) VALUES ('extended_paths', 'on');"
	mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "INSERT INTO cacti.settings (name, value) VALUES ('boost_png_cache_enable', 'on');"
	mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "INSERT INTO cacti.settings (name, value) VALUES ('automation_graphs_enabled', 'on');"
	mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "INSERT INTO cacti.settings (name, value) VALUES ('realtime_cache_path', '/var/www/html/cache/');"
	echo "Database Imported successfully"
}

load_temple_config(){
    echo "$(date +%F_%R) [New Install] Installing supporting template files."
   for filename in /var/www/html/templates/*.xml; do
		  echo "$(date +%F_%R) [New Install] Installing template file $filename"
		  php -q /var/www/html/cli/import_template.php --filename=$filename > /dev/null
   done
}


  
modify_service(){	
	chkconfig crond on
	chkconfig httpd on
	chkconfig rsyslog on
    chkconfig ntp on
	chkconfig snmpd on
	service httpd restart
	service crond restart
	service rsyslog restart
	service ntp restart
	service snmpd restart
}
# Check Database Status and update if needed
#if [[ $(mysql -h "${DB_HOST}"  -P "${DB_PORT}" -u "${DB_USER}" -P "${DB_PASSWORD}"-e "show databases" | grep cacti) != "cacti" ]]; then
    create_db
    import_db
#fi
load_temple_config
#modify_service
