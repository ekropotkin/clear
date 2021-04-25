#!/bin/bash

# do we still need this?
pgpass="/usr/local/share/zabbix/scripts/.pgpass"

# vars
dbhost=127.0.0.1
dbhname="zabbix"
dbport=5432
username=$(cat /etc/zabbix/zabbix_server.conf | grep DBUser | grep -v "#" | cut -d "=" -f 2)
pass=$(cat /etc/zabbix/zabbix_server.conf | grep DBPassword | grep -v "#" | cut -d "=" -f 2)
export PGPASSWORD=$pass

# Data retention in days (two step operation: first truncate, than delete)
REM_DAY=$(date -d "64 day ago" "+%Y_%m_%d")
REM_DAY1=$(date -d "65 day ago" "+%Y_%m_%d")

echo "(( "$(date)" )) Clean history tables "$REM_DAY >> /back/clean.log


#1 Cleanup publica data - 190 days of lifetime for Evenets data
echo "delete alerts "$(date) >> /back/clean.log
time sudo -u postgres /usr/bin/psql -d zabbix -c "delete FROM alerts where clock < (extract(epoch from now())-(190*24*3600))::integer;" 2>&1 >> /back/clean.log
echo "delete acknowledges "$(date) >> /back/clean.log
time sudo -u postgres /usr/bin/psql -d zabbix -c "delete FROM acknowledges where clock < (extract(epoch from now())-(190*24*3600))::integer;" 2>&1 >> /back/clean.log
echo "delete events "$(date) >> /back/clean.log
time sudo -u postgres /usr/bin/psql -d zabbix -c "delete FROM events where clock < (extract(epoch from now())-(190*24*3600))::integer;" 2>&1 >> /back/clean.log
echo "delete eventstm "$(date) >> /back/clean.log
time sudo -u postgres /usr/bin/psql -d zabbix -c "delete FROM eventstm where eupclk < (extract(epoch from now())-(190*24*3600))::integer;" 2>&1 >> /back/clean.log


#2 Use DML to clean tables - Truncate data
echo "(( "$(date)" )) truncate tables: "$REM_DAY >> /back/clean.log
echo "TRUNCATE TABLE partitions.history_log_p$REM_DAY" "  | psql  -h $dbhost -p $dbport -U $username"
echo "TRUNCATE TABLE partitions.history_log_p$REM_DAY"   | psql  -h $dbhost -p $dbport -U "$username" zabbix 2>&1 >> /back/clean.log
echo "TRUNCATE TABLE partitions.history_p$REM_DAY"   | psql  -h $dbhost -p $dbport -U "$username" zabbix 2>&1 >> /back/clean.log
echo "TRUNCATE TABLE partitions.history_str_p$REM_DAY"   | psql  -h $dbhost -p $dbport -U "$username" zabbix 2>&1 >> /back/clean.log
echo "TRUNCATE TABLE partitions.history_text_p$REM_DAY"   | psql  -h $dbhost -p $dbport -U "$username" zabbix 2>&1 >> /back/clean.log
echo "TRUNCATE TABLE partitions.history_uint_p$REM_DAY"   | psql  -h $dbhost -p $dbport -U "$username" zabbix 2>&1 >> /back/clean.log


#3 Use DDL to remove old tables
echo "drop tables "$(date) >> /back/clean.log
time sudo -u postgres /usr/bin/psql -d zabbix -c "DROP TABLE partitions.history_log_p$REM_DAY1" 2>&1 >> /back/clean.log
time sudo -u postgres /usr/bin/psql -d zabbix -c "DROP TABLE partitions.history_p$REM_DAY1" 2>&1 >> /back/clean.log
time sudo -u postgres /usr/bin/psql -d zabbix -c "DROP TABLE partitions.history_str_p$REM_DAY1" 2>&1 >> /back/clean.log
time sudo -u postgres /usr/bin/psql -d zabbix -c "DROP TABLE partitions.history_text_p$REM_DAY1" 2>&1 >> /back/clean.log
time sudo -u postgres /usr/bin/psql -d zabbix -c "DROP TABLE partitions.history_uint_p$REM_DAY1" 2>&1 >> /back/clean.log


echo "Cleanup: completd at "$(date) >> /back/clean.log
echo "-----------------------------------------------" >> /back/clean.log
echo " " >> /back/clean.log
echo " " >> /back/clean.log


