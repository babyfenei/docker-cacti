#/bin/bash

cd /var/www/
mkdir -p /var/www/backups
# Remove old backups
find /var/www/backups/* -mtime +5 -exec rm -fr {} \; > /dev/null 2>&1


# Create the filename for the backup
eval `date "+day=%d; month=%m; year=%Y"`
INSTFIL="cacti-backup-$year-$month-$day.tar.gz"

# Dump the MySQL Database
mysqldump -hDB_HOST -PDB_PORT -uDB_USER  -pDB_PASSWORD cacti > /var/www/cacti-backup.sql

# Gzip the whole folder

tar -Pcpzf /var/www/backups/$INSTFIL /var/www/html/*

# Remove the SQL Dump
rm -f /var/www/cacti-backup.sql


