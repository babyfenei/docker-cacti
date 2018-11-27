#!/bin/sh
echo "$(date +%F_%R) [Note] Setting server timezone settings to '${TIMEZONE}'"
rm -rf /etc/localtime
ln -s  /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
linux_zone=`date +"%z"`
mysql_zone=`echo ${linux_zone:0:3}:${linux_zone:3}`
echo "$(date +%F_%R) [New Install] The time zone of MySQL will be set to ${mysql_zone}."

# verify if initial install steps are required, if lock file does not exist run the following   
if [ ! -f /var/www/html/install.lock ]; then
    echo "$(date +%F_%R) [New Install] Lock file does not exist - new install."

    # THIS WAS IN DOCKER-FILE
    # RRDTOOL BASE INSTALL
    echo "$(date +%F_%R) [New Install] Extracting and installing RRDTOOL files"
	mkdir -p /rrdtool
	tar xf /packages/rrdtool/rrdtool*.tar.gz -C /rrdtool --strip-components=1
    	cd /rrdtool/
	sed -i "s#RRDTOOL / TOBI OETIKER#$RRDTOOL_LOGO#g" src/rrd_graph.c
        #Modify watermark transparency
        sed -i "s/water_color.alpha = 0.3;/water_color.alpha = 0.5;/g" src/rrd_graph.c
     	./configure --prefix=/usr/local/rrdtool  > /var/log/build.log 2>&1 && make > /var/log/build.log 2>&1 && make install > /var/log/build.log 2>&1 
    	ln -s /usr/local/rrdtool/bin/rrdtool /bin/rrdtool
    	rm -rf /rrdtool

    # CACTI BASE INSTALL
    echo "$(date +%F_%R) [New Install] Extracting and installing Cacti files to /var/www/html/"
	mkdir -p /cacti
	tar xf /packages/cacti/cacti*.tar.gz -C /cacti --strip-components=1
   	 \cp -rf  /cacti/* /var/www/html/
    	rm -rf /packages/cacti/cacti*.tar.gz
	
    # SPINE BASE INSTALL
    echo "$(date +%F_%R) [New Install] Extracting and installing Spine files"
	mkdir -p /spine
    	tar xf /packages/spine/cacti-spine*.tar.gz -C /spine --strip-components=1
    	cd /spine/ && ./configure  > /var/log/build.log 2>&1 && make  > /var/log/build.log 2>&1 && make install  > /var/log/build.log 2>&1
    	ln -s /usr/local/spine/bin/spine /usr/bin/spine
    	\cp -rf /usr/local/spine/etc/spine.conf.dist /etc/spine.conf
    	rm -rf /spine 


    # BASE CONFIGS
    echo "$(date +%F_%R) [New Install] Copying templated configurations to Spine, Apache, and Cacti."
	source /etc/sysconfig/i18n
	sed -i "s/DB_HOST/$DB_HOST/g"  `grep -rl DB_HOST  /bash/*`
	sed -i "s/DB_PORT/$DB_PORT/g"  `grep -rl DB_PORT  /bash/*`
	sed -i "s/DB_USER/$DB_USER/g"  `grep -rl DB_USER  /bash/*`
	sed -i "s/DB_PASSWORD/$DB_PASSWORD/g"  `grep -rl DB_PASSWORD  /bash/*`
	sed -i "s#TIMEZONE#$TIMEZONE#g" `grep -rl TIMEZONE  /bash/*`

	\cp -rf /bash/cacti.conf /etc/httpd/conf.d/cacti.conf
	\cp -rf /bash/httpd.conf /etc/httpd/conf/httpd.conf
	\cp -rf /bash/php.ini /etc/php.ini
	\cp -rf /bash/rsyslog.conf /etc/rsyslog.conf
	\cp -rf /bash/config.php /var/www/html/include/config.php
	\cp -rf /bash/global.php /var/www/html/include/global.php
	\cp -rf /bash/spine.conf /etc/spine.conf
	\cp -rf /bash/syslog_config.php /var/www/html/plugins/syslog/config.php
        \cp -rf /bash/cacti /etc/cron.d/cacti
	\cp -rf /bash/i18n /etc/sysconfig/i18n
	mkdir -p /var/www/bash/
	\cp -rf /bash/export.sh /var/www/bash/export.sh && chmod +x /var/www/bash/export.sh
	\cp -rf /bash/backup.sh /var/www/bash/backup.sh && chmod +x /var/www/bash/backup.sh
	chown -R apache:apache /var/www
    
else
    echo "$(date +%F_%R) [Note] cacti has installed in this server."
fi


echo "$(date +%F_%R) [New Install] Waiting for database to respond, if this hangs please check MySQL connections are allowed and functional."
while true 
	sleep 3
	do
		echo "$(date +%F_%R) [New Install] nmap ${DB_HOST} -p ${DB_PORT}"  
		if [[ ! -z `nmap ${DB_HOST} -p ${DB_PORT} |grep "open"` ]];then
       			echo "$(date +%F_%R) [New Install] The database connect successfuly"
			break
		else
       			echo "$(date +%F_%R) [New Install] The database cannot connect retry"
		fi
	done		
	#while ! timeout 1 bash -c 'cat < /dev/null > /dev/tcp/${DB_HOST}/${DB_PORT}'; do sleep 3; done
echo "$(date +%F_%R) [New Install] Database is up! - configuring DB located at ${DB_HOST}:${DB_PORT} (this can take a few minutes)."
# if docker was told to setup the database then perform the following
if [ ${INITIALIZE_DB} = 1 ]; then
        echo "$(date +%F_%R) [Database Initialize] The database cacti will be deleted;"
        mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "drop database cacti;"
        echo "$(date +%F_%R) [Database Initialize] The database syslog will be deleted;"
        mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "drop database syslog;"
fi

if [[ $(mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "show databases" | grep cacti) != "cacti" ]]; then    
	echo "$(date +%F_%R) [New Install] Container has been instructed to create new Database on remote system."
	mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "set time_zone = '${mysql_zone}';"
        mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "set global time_zone = '${mysql_zone}';"
        mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "set collation_server = utf8mb4_unicode_ci;"
        mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "set character_set_client = utf8mb4;"
        mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e 'flush privileges;'
	# initial database and user setup
        echo "$(date +%F_%R) [New Install] CREATE database cacti DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
        mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "create database cacti DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
        echo "$(date +%F_%R) [New Install] CREATE database syslog DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
        mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "create database syslog DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
	# allow cacti user access to new database
        echo "$(date +%F_%R) [New Install] GRANT ALL ON ${DB_NAME}.* TO '${DB_USER}' IDENTIFIED BY '*******';"
        mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "grant all on *.* to '${DB_USER}'@'%' identified by '${DB_PASSWORD}'"
        mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e 'flush privileges;'
        # allow required access to mysql timezone table
        echo "$(date +%F_%R) [New Install] GRANT SELECT ON mysql.time_zone_name TO '${DB_USER}' IDENTIFIED BY '${DB_PASSWORD}';"
	mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "GRANT SELECT ON mysql.time_zone_name TO '${DB_USER}' IDENTIFIED BY '${DB_PASS}';"
  
    	# fresh install db merge
	echo "$(date +%F_%R) [New Install] Merging vanilla cacti.sql file to database."
	mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} cacti < /var/www/html/cacti.sql

        # install additional settings
    	echo "$(date +%F_%R) [New Install] Modify some settings!"
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
        mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "REPLACE INTO cacti.settings SET name='path_spine', value='/usr/local/spine/bin/spine';"
else
        echo "$(date +%F_%R) [Note] Database cacti has exits"
                
fi 

# install additional templates
echo "$(date +%F_%R) [New Install] Installing supporting template files."
for filename in /var/www/html/templates/*.xml; do
	echo "$(date +%F_%R) [New Install] Installing template file $filename"
	php -q /var/www/html/cli/import_template.php --filename=$filename --with-template-rras > /dev/null
done

# CLEANUP
echo "$(date +%F_%R) [New Install] Removing temp Cacti and Spine installation files."
rm -rf /bash
rm -rf /packages

# create lock file so this is not re-ran on restart
touch /var/www/html/install.lock
echo "$(date +%F_%R) [New Install] Creating lock file, db setup complete."
    

# correcting file permissions
echo "$(date +%F_%R) [Note] Setting cacti file permissions."
chown -R apache.apache /var/www/


echo "$(date +%F_%R) [Note] Waiting for database to respond, if this hangs please check MySQL connections are allowed and functional."
    while true 
	sleep 3
	do
		echo "$(date +%F_%R) [Note] nmap ${DB_HOST} -p ${DB_PORT}"  
		if [[ ! -z `nmap ${DB_HOST} -p ${DB_PORT} |grep "open"` ]];then
       			echo "$(date +%F_%R) [Note] The database connect successfuly"
			echo "$(date +%F_%R) [Note] Setting database time zone."
			mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "set time_zone = '${mysql_zone}';"
			mysql  -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} -e "set global time_zone = '${mysql_zone}';"
			break
		else
       			echo "$(date +%F_%R) [Note] The database cannot connect retry"
		fi
	done		

# start cron service
echo "$(date +%F_%R) [Note] Starting crond service."
/usr/sbin/crond -n &
chmod 644 /etc/cron.d/cacti

# start snmp servics
echo "$(date +%F_%R) [Note] Starting snmpd service."
snmpd -Lf /var/log/snmpd.log &

# start syslog service
echo "$(date +%F_%R) [Note] Starting rsyslog service."
rsyslogd -f /etc/rsyslog.conf &

# start web service
echo "$(date +%F_%R) [Note] Starting httpd service."
httpd -DFOREGROUND

