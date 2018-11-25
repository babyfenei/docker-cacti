﻿﻿# Cacti 0.8.8h Docker Container
---
 
[![](https://images.microbadger.com/badges/image/babyfenei/cacti-0.8.8h.svg)](https://microbadger.com/images/babyfenei/cacti-0.8.8h "Get your own image badge on microbadger.com")  [![](https://images.microbadger.com/badges/version/babyfenei/cacti-0.8.8h.svg)](https://microbadger.com/images/babyfenei/cacti-0.8.8h "Get your own version badge on microbadger.com")  [![](https://images.microbadger.com/badges/license/babyfenei/cacti-0.8.8h.svg)](https://microbadger.com/images/babyfenei/cacti-0.8.8h "Get your own license badge on microbadger.com")

##### Github Repo: https://github.com/babyfenei/docker-cacti
##### Dockerhub Repo: https://hub.docker.com/r/babyfenei/cacti-0.8.8h/

## Features
1. This docker is based on centos 6.8 version, installed cacti0.8.8h, rrdtool1.4.9, spine0.8.8h to the system

2. Automatically add Chinese Microsoft Yahoo font to centos system, rrdtool and cacti support Chinese by default

3. Customizable rrdtool watermark variable, which can be modified in the variable RRDTOOL_LOGO

4. Automatically add graphic export scripts to automatically export all graphics and data in the graph tree daily and daily according to the date. Export data is saved in the /var/www/export directory

5. Automatically add data backup script, backup data is saved in /var/www/backup directory

6. Added part of the plugin under cacti0.8.8h,including Realtime, Clog, Syslog, Monitor, Nectar, Thold, Watermark, Settings, Cycle, etc.

7. The graph_xport.php file encoding has been changed to solve the garbled problem of the Chinese header graphic export data.

8. Some common settings settings have been modified

9. Increase cacti according to the value of Base_value (1000 or 1024), calculate the flow graph according to 1000 or 1024, including 95 value and bandwidth total.

10. Thold plug-in has integrated the enterprise WeChat alarm function, you only need to set the relevant ID and secret in the settings to use. Please set your own WeChat specific setting method.

---

## Using this image
### Running the container
This docker image is based on cacti0.8.8h. It does not have a database by default. You must use an external mysql database or a mysql database docker image. The database docker image I used in the test environment is million12/mariadb, but this database image cannot modify the time zone. You can also use other mysql images, preferably you can modify the time zone.

### Exposed Ports
The following ports are important and used by Cacti

| Port |     Notes     |  
|------|:-------------:|
|  80  | HTTP GUI Port |
|  514 | SYSLOG   Port |

It is recommended to allow at least one of the above ports for access to the monitoring system. This is translated by the -p hook. For example



### Database deployment
To be able to connect to database we would need one to be running first. Easiest way to do that is to use another docker image. For this purpose we will use our [million12/mariadb](https://registry.hub.docker.com/u/million12/mariadb/) image as our database.

**For more information about million12/MariaDB see our [documentation.](https://github.com/million12/docker-mariadb) **

Example:  

    docker run \
    -d \
    --name cacti-db \
    -p 3306:3306 \
    --env="MARIADB_USER=cactiuser" \
    --env="MARIADB_PASS=my_password" \
    million12/mariadb

***Remember to use the same credentials when deploying cacti image.***

### Environmental Variable Mysql
In this Image you can use environmental variables to connect into external MySQL/MariaDB database.

| Variable|Description|
|:------:|:-----|
|MARIADB_USER|database user|  
|MARIADB_PASS|database password|  
|TIMEZONE|timezone  |

### Cacti Deployment
Now when we have our database running we can deploy cacti image with appropriate environmental variables set.

Example:  

    docker run \
    -d \
    --name cacti \
    -p 80:80 \
    -p 514:514 \
    --env="DB_HOST=localhost" \
    --env="DB_PORT=3306 \
    --env="DB_USER=cactiuser" \
    --env="DB_PASSWORD=cactiuser" \
    --env="TIMEZONE=Asia/Shanghai" \
    --env="RRDTOOL_LOGO=CACTI0.8.8h/RRDTOOL1.4.9-BY:Fenei" \
    --env="INITIALIZE_DB=0" \
    -v '/data/cacti/html':'/var/www/html':'rw' \
    -v '/data/cacti/backups':'/var/www/backups':'rw' \
    -v '/data/cacti/export':'/var/www/export':'rw' \
    babyfenei/cacti-0.8.8h


### Environmental Variable cacti
In this Image you can use environmental variables to connect into external MySQL/MariaDB database.

| Variable|Default|Description|
|:------:|:----:|:-----|
|DB_HOST|localhost|Remote database connection address, using IP or domain name|
|DB_PORT|3306|Remote database connection port|
|DB_USER|cactiuser|Remote database username|
|DB_PASSWORD|cactiuser|Remote database password|
|TIMEZONE|Asia/Shanghai|Cacti server time zone, viewable in /usr/share/zoneinfo|
|RRDTOOL_LOGO|CACTI0.8.8h/RRDTOOL1.4.9-BY:Fenei|Rrdtool logo, you can modify the watermark on the right side of cacti graphics, be careful not to enter #|
|INITIALIZE_DB|0|Initialize the database switch, 1 is initialization, 0 is not, the default is 0. Only valid when the cacti database is detected|


### VOLUME: Mount directory description
|File directory| description|
|:---:|:---:|
|/var/www/html | cacti master files.|
|/var/www/backups| cacti backup file, daily backup, default data backup file within 7 days.|
|/var/www/export | cacti graphics data export file, automatically export graphics in the number of graphics, including graphics and raw data. The daily flow chart is exported daily, and the monthly monthly flow chart is exported monthly. You can also use English () after the graphic name to define the monthly traffic export date in parentheses.|

### Access Cacti web interface
To log in into cacti for the first time use credentials `admin:admin`. System will ask you to change those when logged in for the firts time.

### Notice
If realtime has graphics and data, but the graphics list has no data, please use `select * from cacti.poller_time;` in the mysql database to query the poller time. If the time does not match the cacti server time, you need to modify the mysql database server. Time or use `set time_zone = '${mysql_zone}';`Modify database time


