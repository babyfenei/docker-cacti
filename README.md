﻿# Cacti 0.8.8h Docker Container
---
 
[![](https://images.microbadger.com/badges/image/babyfenei/cacti-0.8.8h.svg)](https://microbadger.com/images/babyfenei/cacti-0.8.8h "Get your own image badge on microbadger.com")

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
This container contains Cacti v1+ and is not compatible with older version of cacti. It does rely on an external MySQL database that can be already configured before initial startup or having the container itself perform the setup and initialization. If you want this container to perform these steps for you, you will need to pass the root password for mysql login or startup will fail. This container automatically incorporates Cacti Spine's multithreaded poller.

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
### Environmental Variable
In this Image you can use environmental variables to connect into external MySQL/MariaDB database.

`DB_USER` = database user  
`DB_PASS` = database password  
`DB_ADDRESS` = database address (either ip or domain-name)  
`TIMEZONE` = timezone  

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
    -v '/data/cacti':'/var/www':'rw' \
    babyfenei/cacti-0.8.8h

### Access Cacti web interface
To log in into cacti for the first time use credentials `admin:admin`. System will ask you to change those when logged in for the firts time.








