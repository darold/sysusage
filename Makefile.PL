use ExtUtils::MakeMaker qw(prompt WriteMakefile);

my @ALLOWED_ARGS = ('BINDIR','CONFDIR','PIDDIR','BASEDIR','PLUGINDIR','HTMLDIR','MANDIR','DOCDIR','DESTDIR','QUIET','INSTALLDIRS','REMOTE');

# Parse command line arguments and store them as environment variables
while ($_ = shift) {
	my ($k,$v) = split(/=/, $_, 2);
	if (grep(/^$k$/, @ALLOWED_ARGS)) {
		$ENV{$k} = $v;
	}
}
$ENV{DESTDIR} =~ s/\/$//;

my $default_html = '/var/www';
foreach my $d ('/var/www/htdocs', '/var/www/html') {
	$default_html = $d, last if (-d $d);
}
$default_html .= '/sysusage';

# Default install path
my $BINDIR = $ENV{BINDIR} || '/usr/local/sysusage/bin';
my $CONFDIR = $ENV{CONFDIR} || '/usr/local/sysusage/etc';
my $PIDDIR = $ENV{PIDDIR} || '/usr/local/sysusage/etc';
my $BASEDIR = $ENV{BASEDIR} || '/usr/local/sysusage/rrdfiles';
my $PLUGINDIR = $ENV{PLUGINDIR} || '/usr/local/sysusage/plugins';
my $HTMLDIR = $ENV{HTMLDIR} || $default_html;
my $MANDIR = $ENV{MANDIR} || '/usr/local/sysusage/doc';
my $DOCDIR = $ENV{DOCDIR} || '/usr/local/sysusage/doc';
my $DESTDIR = $ENV{DESTDIR} || '';
my $REMOTE = $ENV{REMOTE} || 0;

# Try to find all binary used by SysUsage
my $hostname = `which hostname 2>/dev/null`;
chomp($hostname);
if (!$hostname) {
	die "NOTICE: This tool requires system command: hostname, can't find it in your path\n";
}
my $sar = `which sar 2>/dev/null`;
chomp($sar);
if (!$sar) {
	die "NOTICE: This tool requires the sysstat package, can't find sar in your path\n";
}
my $uptime = `which uptime 2>/dev/null`;
chomp($uptime);
if (!$uptime) {
	die "NOTICE: This tool requires system command: uptime, can't find it in your path\n";
}

my $sensors = `which sensors 2>/dev/null`;
chomp($sensors);
my $hddtemp = `which hddtemp 2>/dev/null`;
chomp($hddtemp);
my $ssh = `which ssh 2>/dev/null`;
chomp($ssh);
$ssh ||= 'ssh';
my $ssh_timeout = 5;

# Setup ok. generating sysusage.cfg config file
unless(open(OUTCFG, ">sysusage.cfg")) {
	print "\nError: can't write config file sysusage.cfg, $!\n";
	exit 0;
}

print OUTCFG qq{
# This part configure the default settings of Sysusage perl scripts
[GENERAL]
DEBUG       = 0
DATA_DIR    = $BASEDIR
PID_DIR     = $PIDDIR
DEST_DIR    = $HTMLDIR
SAR_BIN     = $sar
UPTIME      = $uptime
HOSTNAME    = $hostname
INTERVAL    = 60
SKIP        = 
HDDTEMP_BIN = $hddtemp
SENSORS_BIN = $sensors
DAEMON      = 0
GRAPH_WIDTH = 800
GRAPH_HEIGHT= 350
FLAMING     = 0
HIRES       = 0
LINE_SIZE   = 1
PROC_QSIZE  = 4
RESRC_URL   =
SSH_BIN     = $ssh
SSH_OPTIONS = -o ConnectTimeout=$ssh_timeout -o PreferredAuthentications=hostbased,publickey
SSH_USER    =
SSH_IDENTITY=

# This part enable/disable and configure smtp alarm report and/or Nagios
# message report (path to nagios binary submit_check_result) when threshold
# min/max exceed are detected. Upper and lower level values are use to set
# the alarm level. With Nagios 0=OK, 1=WARNING, 2=Critical, 3=Unknown.
# Default is to send warning on high value and critical on low threshold value.
# Typically a high load average can be seen as a warning and the shutdown of
# any monitored daemon as critical. To enable set WARN_MODE to 1.
[ALARM]
WARN_MODE   = 0
ALARM_PROG  = $BINDIR/sysusagewarn
SMTP        = localhost
FROM        = root\@localhost
TO          = root\@localhost
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
# Omitting ThresholdMin disable warning.
# You can delay the call to the alarm program at threshold exceed by specifying
# the number of consecutive exceed attempt before the command will be called.
# Just specify the number of attempt between bracket just after the min and/or
# max threshold value, format:
#
#	type:what:ThresholdMax(attempt):ThresholdMin(attempt)
#
# for example:
#
#	load:12(3):
#
# will send an alarm when the system load average will exceed 12 after three
# consecutives attempts at the define interval. If the interval is 60 seconds,
# the alarm will be sent up to 180 second after the first exceed.
#
# The 'cpu' target monitoring type will report all statictics per cpu. This can
# represent a lot of informations if you have several cpu. To limit statistics
# to total cpu only, you must replace default 'cpu' target to 'cpuall' in your
# configuration file.
#
# See documentation for more explanation
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
tproc:
queue:
dev:
huge:
#hddtemp:
#sensors:
#temp:
#fan:

# This part enable the use of custom plugins. You can call any program/script
# provide that it return 3 numbers separated by a space character. See plugins/
# directory for an example.
# 
[PLUGIN testplug1]
title:WWW response time plugin
menu:Web servers
enable:no
multi:no
program:$PLUGINDIR/plugin-sample1.pl
minThreshold:0
maxThreshold:10
delayThreshold:1
verticallabel:Number of seconds
label1:www.server.test response time
label2:
label3:
legend1:seconds
legend2:
legend3:
remote:yes

[PLUGIN testplug2]
title:ICMP servers response time
menu:Network latency
enable:no
multi:no
program:$PLUGINDIR/plugin-sample2.pl
minThreshold:
maxThreshold:
delayThreshold:
verticallabel:Response time in milliseconds
label1:Server1
label2:Server2
label3:Server3
legend1:ms
legend2:ms
legend3:ms
remote:yes
};

# If this is not an install on a remote host
if (!$REMOTE) {
	print OUTCFG qq{
[REMOTE hostname1]
enable:no
ssh_user:monitor
ssh_identity:/home/monitor/.ssh/id_rsa
#ssh_options:
#ssh_command:
remote_sysusage:$BINDIR/rsysusage

#[GROUP Web Servers]
#hostname1
#hostname2

};
}
close(OUTCFG);

unless(open(INST, ">install_all.sh")) {
	print "\nError: can't write post install file install_all.sh, $!\n";
	exit 0;
}
print INST qq{#!/bin/sh
REMOTE=$REMOTE
if [ ! -d "$DESTDIR$BINDIR" ]; then
	mkdir -p $DESTDIR$BINDIR
fi
if [ ! -d "$DESTDIR$CONFDIR" ]; then
	mkdir -p $DESTDIR$CONFDIR
fi
if [ ! -d "$DESTDIR$PLUGINDIR" ]; then
	mkdir -p $DESTDIR$PLUGINDIR
fi
if [ ! -d "$DESTDIR$BASEDIR" ]; then
	mkdir -p $DESTDIR$BASEDIR
fi
if [ \$REMOTE -eq 0 ]; then
	if [ ! -d "$DESTDIR$HTMLDIR" ]; then
		mkdir -p $DESTDIR$HTMLDIR
	fi
fi
if [ ! -d "$DESTDIR$MANDIR" ]; then
	mkdir -p $DESTDIR$MANDIR
fi
if [ ! -d "$DESTDIR$DOCDIR" ]; then
	mkdir -p $DESTDIR$DOCDIR
fi

if [ -e $DESTDIR$CONFDIR/sysusage.cfg ]; then
	echo "File sysusage.cfg already exists, the new one will be created as sysusage.cfg.new"
	install -m 644 sysusage.cfg $DESTDIR$CONFDIR/sysusage.cfg.new
else
	install -m 644 sysusage.cfg $DESTDIR$CONFDIR/
fi
install -m 755 bin/rsysusage $DESTDIR$BINDIR/
if [ \$REMOTE -eq 0 ]; then
	install -m 755 bin/sysusage $DESTDIR$BINDIR/
	install -m 755 bin/sysusagegraph $DESTDIR$BINDIR/
	install -m 755 bin/sysusagejqgraph $DESTDIR$BINDIR/
	install -m 755 bin/sysusagewarn $DESTDIR$BINDIR/
	install -m 644 resources/sysusage-logo.png $DESTDIR$HTMLDIR/
	install -m 644 resources/sysusage.css $DESTDIR$HTMLDIR/
	install -m 644 resources/sysusage.js $DESTDIR$HTMLDIR/
	install -m 644 resources/sysusage_arrow.png $DESTDIR$HTMLDIR/
	install -m 644 resources/favicon.ico $DESTDIR$HTMLDIR/
	tar xzf resources/jqplot-sysusage.tar.gz --directory $DESTDIR$HTMLDIR/
fi
install -m 755 plugins/plugin-sample1.pl $DESTDIR$PLUGINDIR/
install -m 755 plugins/plugin-sample2.pl $DESTDIR$PLUGINDIR/
install -m 644 doc/sysusage.1 $DESTDIR$MANDIR/
install -m 644 README $DESTDIR$DOCDIR/
install -m 644 ChangeLog $DESTDIR$DOCDIR/

};
if (!$REMOTE && !$ENV{QUIET}) {
	print INST qq{
echo "
Now you can run sysusage into you crontab as follow:

	*/1 * * * * $BINDIR/sysusage > /dev/null 2>&1
	*/5 * * * * /usr/bin/nice -19 $BINDIR/sysusagejqgraph > /dev/null 2>&1

If you don't want to use the jqplot javascript graph library use this instead:

	*/5 * * * * /usr/bin/nice -19 $BINDIR/sysusagegraph > /dev/null 2>&1

If you need to monitor your host under the minute, you can use DEAMON mode.
See $DOCDIR/README file.
"
};
}
close(INST);
`chmod 755 install_all.sh`;

`perl -p -i -e 's#my \\\$CONF_DIR .*#my \\\$CONF_DIR = "$CONFDIR";#' bin/*`;

WriteMakefile(
    'NAME'         => 'SysUsage::Sar',
    'VERSION_FROM' => 'Sar.pm',
    'dist'         => {
			'COMPRESS'=>'gzip -9f', 'SUFFIX' => 'gz',
			'ZIP'=>'/usr/bin/zip','ZIPFLAGS'=>'-rl'
		      },
    'AUTHOR'       => 'Gilles Darold (gilles@darold.net)',
    'ABSTRACT'     => 'System Usage Monitoring',
    'DESTDIR'      => $ENV{DESTDIR},
    'INSTALLDIRS'  => $ENV{INSTALLDIRS},
    'clean'        => {FILES => "install_all.sh sysusage.cfg"}
);

sub MY::install {
	my $self = shift;

	my $string = $self->MM::install;
	$string =~ s/(pure_install\s+)(.*)/$1 install_all $2/;

	return $string;
}

sub MY::postamble {
	my $postamble = <<'END';
install_all: install_all.sh
	sh install_all.sh
END
	return $postamble;
}

if (!$ENV{QUIET}) {
	print "Done...\n\n";
	print "Now type 'make && make install'\n\n";
}

