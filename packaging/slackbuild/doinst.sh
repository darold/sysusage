#! /bin/sh
 
# Create crontab entry
cat > sysusage.cron << _EOF_
#
# System monitoring
#*/1 * * * * /usr/bin/sysusage > /dev/null 2>&1
#*/5 * * * * /usr/bin/sysusagegraph > /dev/null 2>&1
_EOF_

# Create default httpd configuration
cat > httpd-sysusage.conf << _EOF_
#
# By default SysUsage statistics are only accessible from the local host.
#
Alias /sysusage /var/www/sysusage

<Directory /var/www/sysusage>
    Options All
    Order deny,allow
    Deny from all
    Allow from 127.0.0.1
    Allow from ::1
    # Allow from .example.com
</Directory>
_EOF_

# Append crontab entry to root user
cat sysusage.cron >> /var/spool/cron/crontabs/root
rm -f sysusage.cron
# Append Apache configuration
install -D -m 0644 httpd-sysusage.conf /etc/httpd/extra/httpd-sysusage.conf

cat >> /etc/httpd/httpd.conf << _EOF_

# Uncomment the following line to limit access to SysUsage statistics
#
#Include /etc/httpd/extra/httpd-sysusage.conf

_EOF_

cat install/README.Slackware

