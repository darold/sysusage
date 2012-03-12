#!/bin/sh
#
# Script used to create the Debian package tree
#
mkdir -p sysusage/usr/lib/perl5/auto/SysUsage/Sar
cp ../../Sar.pm sysusage/usr/lib/perl5/
mkdir -p sysusage/usr/share/man/man1
cp ../../doc/sysusage.1 sysusage/usr/share/man/man1/
mkdir -p sysusage/usr/share/sysusage
cp ../../plugins/* sysusage/usr/share/sysusage/
mkdir -p sysusage/usr/share/apache2/sysusage
cp ../../resources/sysusage-logo.png sysusage/usr/share/apache2/sysusage/
cp ../../resources/sysusage.css sysusage/usr/share/apache2/sysusage/
cp ../../resources/sysusage.js sysusage/usr/share/apache2/sysusage/
cp ../../resources/sysusage_arrow.png sysusage/usr/share/apache2/sysusage/
cp ../../resources/favicon.ico sysusage/usr/share/apache2/sysusage/
tar xzf ../../resources/jqplot-sysusage.tar.gz --directory sysusage/usr/share/apache2/sysusage/
mkdir -p sysusage/usr/share/doc/sysusage
cp ../../TODO sysusage/usr/share/doc/sysusage/TODO
cp ../../README sysusage/usr/share/doc/sysusage/README
mkdir -p sysusage/usr/bin
cp ../../bin/* sysusage/usr/bin/
perl -p -i -e 's/my \$CONF_DIR =.*/my \$CONF_DIR = "\/etc\/sysusage.conf";/' sysusage/usr/bin/* 
mkdir -p sysusage/var/lib/sysusage
mkdir -p sysusage/etc
cat > sysusage/etc/sysusage.conf << _EOF_
# This part configure the default settings of Sysusage perl scripts
[GENERAL]
DEBUG       = 0
DATA_DIR    = /var/lib/sysusage
PID_DIR     = /var/run/
DEST_DIR    = /usr/share/apache2/sysusage/
SAR_BIN     = /usr/bin/sar
UPTIME      = /usr/bin/uptime
HOSTNAME    = /bin/hostname
INTERVAL    = 60
SKIP        = 
HDDTEMP_BIN = /usr/sbin/hddtemp
SENSORS_BIN = 
DAEMON      = 0
GRAPH_WIDTH = 550
GRAPH_HEIGHT= 200

# This part enable/disable and configure smtp alarm report and/or Nagios
# message report (path to nagios binary submit_check_result) when threshold
# min/max exceed are detected. Upper and lower level values are use to set
# the alarm level. With Nagios 0=OK, 1=WARNING, 2=Critical, 3=Unknown.
# Default is to send warning on high value and critical on low threshold value.
# Typically a high load average can be seen as a warning and the shutdown of
# any monitored daemon as critical. To enable set WARN_MODE to 1.
[ALARM]
WARN_MODE   = 0
ALARM_PROG  = /usr/bin/sysusagewarn
SMTP        = localhost
FROM        = root@localhost
TO          = root@localhost
NAGIOS      =
UPPER_LEVEL = 1
LOWER_LEVEL = 2
URL         =
SKIP        =

# This part allow system monitoring. There's three format. The first one is
# the most used:
#
#	type:ThresholdMax:ThresholdMin
#
# where type is the type of monitoring.
# The second format is only used for process and queue monitoring:
#
#	type:what:ThresholdMax:ThresholdMin
#
# where type can be 'proc' or 'queue' and what is the related thing to monitor.
# If type is 'proc' then what is a process name, if type is 'queue' then what
# is a directory path to monitor.
#
# The last one is used for disk space monitoring:
#
#       disk:ThresholdMax:exclusion
#
# where exclusion is a semicolon (;) separated list of mount point to exclude
# from monitoring.
#
# A ThresholdMax value set to 0 or omitted mean disable warning
# Omitting ThresholdMin disable warning
#
[MONITOR]
load:
cpu:
cswch:
intr:
mem:
share:
swap:
work:
sock:
socktw:
io:
file:
page:
pcrea:
pswap:
net:
err:
disk:
tcp:
proc:
queue:
dev:
hddtemp:
sensors:

# This part enable the use of custom plugins. You can call any program/script
# provide that it return 3 numbers separated by a space character. See plugins/
# directory for an example.
# 
[PLUGIN testplug1]
title:WWW response time plugin
enable:no
program:/usr/share/sysusage/plugin-sample1.pl
minThreshold:0
maxThreshold:10
verticallabel:Number of seconds
label1:www.server.test response time
label2:
label3:
legend1:seconds
legend2:
legend3:

[PLUGIN testplug2]
title:ICMP servers response time
enable:no
program:/usr/share/sysusage/plugin-sample2.pl
minThreshold:
maxThreshold:
verticallabel:Response time in milliseconds
label1:Server1
label2:Server2
label3:Server3
legend1:ms
legend2:ms
legend3:ms

_EOF_


