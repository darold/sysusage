#!/usr/bin/perl
#------------------------------------------------------------------------
#
# This script is use to demonstrate the plugin method used by Sysusage.
#
# A monitoring plugin can monitor everything you want provide that it
# return 1 to 3 values.
#
# This example monitor the icmp response time of tree servers  and print
# the number of milliseconds it tooks.
# See configuration file at [CUSTOM ...] section to see howto call it.
#
#------------------------------------------------------------------------
use strict;

use Net::Ping;

my @SERVERS = ('192.168.1.1', '192.168.1.2', '192.168.1.3');
my @ret = ();
foreach my $host (@SERVERS) {
	# High precision syntax (requires Time::HiRes)
	my $p = Net::Ping->new();
	$p->hires();
	my ($ret, $duration, $ip) = $p->ping($host, 3);
	my $time = localtime(time);
	if ($ret) {
		#printf("$time $host [ip: $ip] is alive (packet return time: %.2f ms)\n", 1000 * $duration);
		push(@ret, sprintf("%.2f", 1000 * $duration));
	} else {
		push(@ret, "0");
	}
	$p->close();
}

print join(" ", @ret), "\n";

exit 0;
