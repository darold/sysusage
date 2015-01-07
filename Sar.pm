package SysUsage::Sar;
#------------------------------------------------------------------------------
# sysusage - Full system monitoring with RRDTOOL
# Copyright (C) 2003-2015 Gilles Darold
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 3 of the License, or
#   any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software Foundation,
#   Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
#
# Author: Gilles Darold <gilles@darold.net>
#
# This module grab system information retrieve from sar command
# and provide all method to get these informations.
#------------------------------------------------------------------------------
use strict qw(vars);
use open ':locale';

BEGIN {
        use Exporter();
        use vars qw($VERSION $COPYRIGHT $AUTHOR @ISA @EXPORT);
        $VERSION = '5.4';
        $COPYRIGHT = 'Copyright (c) 2003-2015 Gilles Darold - All rights reserved.';
        $AUTHOR = "Gilles Darold - gilles\@darold.net";

        @ISA = qw(Exporter);
        @EXPORT = qw//;

        $| = 1;

}

sub new
{
	my ($class, %options) = @_;

	my $self = {
		'header'  => '',
		'report'  => (),
		'data'    => (),
		'debug'   => 0,
		'sar_cmd' => '',
	};
	bless $self, $class;

	$self->init(%options);

	return ($self);
}

sub init
{
	my ($self, %options) = @_;

	#### Set the sar command to execute.
	my $sar = $options{'sar'} || '/usr/bin/sar';
	if (!-x $sar) {
		die "ERROR: Can't find sar binary at $sar\n";
	}
	my $opt = $options{'opt'} || '-p -A 1 5';
	$self->{'sar_cmd'} = $sar . ' ' . $opt . ' | grep -v -E "^[0-9]"';
	$self->{'debug'} = $options{'debug'} || 0;

	$self->{'sar_version'} = `LC_ALL=C $sar -V 2>&1 | grep "sysstat version"`;
	chomp($self->{'sar_version'});
	$self->{'sar_version'} =~ s/sysstat version //;

}

# Return sar output first line.  Usually kernel information
sub getHeader
{
	my ($self) = @_;

	return $self->{header};
}

# Parse Sar output and return a hash
sub parseSarOutput
{
	my ($self) = @_;

	#### Execute sar command and get result
	unless(open(SAR, "LC_ALL=C $self->{sar_cmd} |")) {
		die "ERROR: Can't execute command: LC_ALL=C $self->{'sar_cmd'}\n";
	}
	while (my $line = <SAR>) {
		$line =~ s///gs;
		chomp($line);
		push(@{$self->{data}}, $line);
	}
	close(SAR);

	#### Extract sar head line. Usually kernel information
	$self->{header} = shift(@{$self->{data}});
	print STDERR "Sar header: $self->{header}\n" if ($self->{'debug'});


	my $type = '';
	my @headers = ();
	my @values = ();
	for (my $i = 0; $i <= $#{$self->{data}}; $i++) {
		# Empty line, maybe the end of a report
		if (!$self->{data}[$i]) {
			$type = '';
			@headers = ();
			@values = ();
			next;
		}
		# Remove average header
		$self->{data}[$i] =~ s#^[\w]+:[\s\t]+##i;
		# Store all header fields
		if ($#headers == -1) {
			push(@headers, split(m#\s+#, $self->{data}[$i]));
		}
		# Try to find the kind of report
		if ($self->{data}[$i] =~ m#^proc/s#) {
			$type = 'pcrea';
			next;
		}
		if ($self->{data}[$i] =~ m#^cswch/s#) {
			$type = 'cswch';
			next;
		}
		if ($self->{data}[$i] =~ m#^CPU\s+i\d+#) {
			$type = 'ncpu';
			$headers[0] = 'number';
			next;
		} elsif ($self->{data}[$i] =~ m#^CPU\s+M#) {
			$type = 'mcpu';
			$headers[0] = 'number';
			next;
		} elsif ($self->{data}[$i] =~ m#^CPU\s+w#) {
			$type = 'wcpu';
			$headers[0] = 'number';
			next;
		} elsif ($self->{data}[$i] =~ m#^CPU\s+#) {
			$type = 'cpu';
			$headers[0] = 'number';
			next;
		}
		if ($self->{data}[$i] =~ m#^INTR\s+#) {
			$type = 'intr';
			$headers[0] = 'name';
			next;
		}
		if ($self->{data}[$i] =~ m#^pgpgin/s\s+#) {
			$type = 'page';
			next;
		}
		if ($self->{data}[$i] =~ m#^pswpin/s\s+#) {
			$type = 'pswap';
			next;
		}
		if (( $self->{data}[$i] =~ m#^tps\s+#) && ($self->{data} !~ m#DEV\s+#) ) {
			$type = 'io';
			next;
		}
		if ($self->{data}[$i] =~ m#^frmpg/s\s+#) {
			$type = 'mpage';
			next;
		}
		if ($self->{data}[$i] =~ m#^TTY\s+#) {
			$type = 'tty';
			$headers[0] = 'number';
			next;
		}
		if ($self->{data}[$i] =~ m#^IFACE\s+rxpck/s\s+#) {
			$type = 'net';
			$headers[0] = 'name';
			next;
		}
		if ($self->{data}[$i] =~ m#^IFACE\s+rxerr/s\s+#) {
			$type = 'err';
			$headers[0] = 'name';
			next;
		}
		if ($self->{data}[$i] =~ m#^DEV\s+#) {
			$type = 'dev';
			$headers[0] = 'name';
			next;
		}
		if ($self->{data}[$i] =~ m#^kbmemfree\s+#) {
			$type = 'mem';
			next;
		}
		# New in sysstat 8.1.5
		if ($self->{data}[$i] =~ m#^kbswpfree\s+#) {
			$type = 'swap';
			next;
		}
		if ($self->{data}[$i] =~ m#^dentunusd\s+#) {
			$type = 'file';
			next;
		}
		if ($self->{data}[$i] =~ m#^totsck\s+#) {
			$type = 'sock';
			next;
		}
		if ($self->{data}[$i] =~ m#^runq-sz\s+#) {
			$type = 'load';
			next;
		}
		# New in 8.1.7
		if ($self->{data}[$i] =~ m#^active\/s\s+#) {
			$type = 'tcp';
			next;
		}
		# Unknow type of report, skipping
		if (!$type) {
			@headers = ();
			@values = ();
			next;
		}
		# Get all values reported
		push(@values, split(m#\s+#, $self->{data}[$i]));
		if ($#values != $#headers) {
			die "ERROR: Parsing of sar output reports different values than headers allow. ($#values != $#headers)\n";
		}
		# Store all into the main hash
		for (my $j = 0; $j <= $#headers; $j++) {
			# Remove extra info into headers
			$headers[$j] =~ s#/s##g;
			# Change decimal character to perl
			$values[$j] =~ s/,/\./;
			# New version of sar report proc and cswch at same time
			if ( ($#headers == 1) && ($headers[$j] eq 'cswch') ) {
				$self->{report}{'cswch'}{$headers[$j]} = $values[$j];
			} elsif ( ($type eq 'mem') && ($headers[$j] eq '%swpused') ) {
				$self->{report}{'swap'}{$headers[$j]} = $values[$j];
print STDERR "Sar report 'swap': $headers[$j] => $self->{report}{'swap'}{$headers[$j]}\n" if ($self->{'debug'});
			} elsif ( ($type eq 'mem') && ($headers[$j] eq '%commit') ) {
				$self->{report}{'work'}{$headers[$j]} = $values[$j];
print STDERR "Sar report 'work': $headers[$j] => $self->{report}{'work'}{$headers[$j]}\n" if ($self->{'debug'});
			} elsif ( ($type eq 'mem') && ($headers[$j] eq 'kbcommit') ) {
				$self->{report}{'work'}{$headers[$j]} = $values[$j];
print STDERR "Sar report 'work': $headers[$j] => $self->{report}{'work'}{$headers[$j]}\n" if ($self->{'debug'});
			} elsif (!grep(/^$headers[0]$/, 'name', 'number')) {
				$self->{report}{$type}{$headers[$j]} = $values[$j];
print STDERR "Sar report '$type': $headers[$j] => $self->{report}{$type}{$headers[$j]}\n" if ($self->{'debug'});
			} else {
				next if ( ($type eq 'intr') && ($values[0] ne 'sum') );
				$headers[$j] = '%user' if ( ($type eq 'cpu') && ($headers[$j] eq '%usr'));
				$headers[$j] = '%system' if ( ($type eq 'cpu') && ($headers[$j] eq '%sys'));
				$self->{report}{$type}{$values[0]}{$headers[$j]} = $values[$j];
print STDERR "Sar report '$type' ($values[0]): $headers[$j] => $self->{report}{$type}{$values[0]}{$headers[$j]}\n" if ($self->{'debug'});
			}
		}
		@values = ();
	}
}

# Return a hash of the given SAR type of report.
sub getReportType
{
	my ($self, $type) = @_;

	die "ERROR: bad report type $type\n" if (!exists $self->{report}{$type});

	return %{$self->{report}{$type}};

}

sub getReport
{
	my ($self, $type) = @_;

	return %{$self->{report}};

}


1;

__END__
