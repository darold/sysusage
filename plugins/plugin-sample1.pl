#!/usr/bin/perl
#------------------------------------------------------------------------
#
# This script is use to demonstrate the plugin method used by Sysusage.
#
# A monitoring plugin can monitor everything you want provide that it
# return 1 to 3 values.
#
# This example monitor the real response time of a web server and print
# the number of seconds it tooks.
# See configuration file at [CUSTOM ...] section to see howto call it.
#
#------------------------------------------------------------------------
use strict;

# Use the time system command to get the response time of an URL called
# with wget.
my $time = `/usr/bin/time -f "\%E" /usr/bin/wget -o /tmp/wget.out -O /dev/null "http://www.mydom.dom/thePage.html" 2>&1"`;
chomp($time);

my $sec = 0;
if ($time =~ /^(\d+):(\d+\.\d+)/) {
	$sec = ($2 + ($1 * 60));
}

# Plugin may always return 3 numbers corresponding to the 3 possibles
# views in one graph. If you only have one return value, other should
# be set to 0.
print "$sec 0 0\n";

exit 0;
