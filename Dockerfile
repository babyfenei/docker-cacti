FROM centos:6.8

MAINTAINER Fenei <babyfenei@qq.com>

# Build-time metadata as defined at http://label-schema.org
ARG BUILD_DATE
ARG VERSION
LABEL build_version="babyfenei/cacti-0.8.8h version:- ${VERSION} Build-date:- ${BUILD_DATE}"

### 安装依赖
RUN \
    mkdir -p /data/logs/ && \
    curl -o /etc/yum.repos.d/CentOS-Base.repo -O http://mirrors.aliyun.com/repo/Centos-6.repo && \
    yum install -y epel-release && \
    yum install -y perl-devel  php-gmp php-opcache php-devel php-mbstring php-mcrypt php-mysql php-phpunit-PHPUnit \
    php-gd php-xml  php-ldap php-mbstring php-mcrypt php-pecl-xdebug php-pecl-xhprof php-opcache php-pecl-redis php-redis \
    php-pecl-xdebug php-pecl-xhprof php-snmp automake mysql-devel  gnumeric  wget gzip help2man libtool make net-snmp-devel \
    m4 nmap sudo glib  openssl-devel dos2unix lsof  redis \
    dejavu-fonts-common dejavu-lgc-sans-mono-fonts dejavu-sans-mono-fonts   \
    net-snmp net-snmp-utils  gcc pango-devel libxml2-devel net-snmp-devel cronie \
    sendmail mailx ImageMagick httpd  rsyslog-mysql vim ntpdate && \
    yum clean all && \
    rpm --rebuilddb && yum clean all

ENV DB_USER=cactiuser \
    DB_PASSWORD=cactiuser \
    DB_HOST=localhost \
    DB_PORT=3306 \
    TIMEZONE=Asia/Shanghai \
    RRDTOOL_LOGO=DOCKER-CACTI0.8.8h/RRDTOOL1.4.9-BY:Fenei \
    INITIALIZE_DB=0 

VOLUME ["/var/www/html"]
VOLUME ["/var/www/backups"]
VOLUME ["/var/www/export"]

COPY container-files / 

EXPOSE 80 514

COPY start.sh /start.sh

CMD [ "bash", "/start.sh" ]
