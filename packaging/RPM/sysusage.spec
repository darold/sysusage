%define uname SysUsage
%define vname Sar
%define wname sysusage
%define webdir %{_localstatedir}/www/%{wname}
%define rundir %{_localstatedir}/run
%define _unpackaged_files_terminate_build 0

Name: %{wname}
Epoch: 0
Version: 5.7
Release: 1%{?dist}
Summary: System monitoring based on perl, rrdtool, and sysstat

Group: System Environment/Daemons
License: GPLv3+
URL: http://sysusage.darold.net/
Source0: http://downloads.sourceforge.net/%{name}/%{uname}-%{vname}-%{version}.tar.gz
BuildArch: noarch
BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

Requires: rrdtool
Requires: sysstat
Requires: httpd
Requires: perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
Requires: vixie-cron

%description
%{uname} is a system monitoring and alarm reporting tool. 
It can generate historical graph views of CPU, memory, IO,
network and disk usage, and very much more.

%prep
%setup -q -n %{uname}-%{vname}-%{version}

# create default crontab entry
%{__cat} > %{wname}.cron << _EOF1_
#* * * * *    root    %{_bindir}/%{wname}      >/dev/null 2>&1
#*/5 * * * *    root    %{_bindir}/%{wname}graph >/dev/null 2>&1
_EOF1_

# create default httpd configuration
%{__cat} > httpd-%{wname}.conf << _EOF2_
#
# By default %{wname} statistics are only accessible from the local host.
# 
#Alias /%{wname} %{webdir}

#<Directory %{webdir}>
    #Options All
    #Order deny,allow
    #Deny from all
    #Allow from 127.0.0.1
    #Allow from ::1
    ## Allow from .example.com
#</Directory>
_EOF2_

# create README.RPM
%{__cat} > README.RPM << _EOF3_
1. Setup a cronjob to run %{wname}.  Uncomment the entries in
   %{_sysconfdir}/cron.d/%{wname} or create a custom cronjob.

2. Uncomment the entries in %{_sysconfdir}/httpd/conf.d/%{wname}.conf.

3. Ensure that httpd is running.

4. Browse to http://localhost/%{wname} to ensure that things are working
   properly.

5. If necessary, give additional hosts access to %{wname} by adding them to
   %{_sysconfdir}/httpd/conf.d/%{wname}.conf.

_EOF3_

%build
# Make Perl and SysUsage distrib files
%{__perl} Makefile.PL \
    INSTALLDIRS=vendor \
    QUIET=1 \
    BINDIR=%{_bindir} \
    CONFDIR=%{_sysconfdir} \
    PIDDIR=%{rundir} \
    BASEDIR=%{_localstatedir}/lib/%{wname} \
    PLUGINDIR=%{_libexecdir}/%{wname} \
    HTMLDIR=%{webdir} \
    MANDIR=%{_mandir}/man1 \
    DOCDIR=%{_docdir}/%{wname}-%{version} \
    DESTDIR=%{buildroot} < /dev/null
%{__make}


# nope, gotta love perl

%install
%{__rm} -rf %{buildroot}
# set up path structure
%{__install} -d -m 0755 %{buildroot}/%{_bindir}
%{__install} -d -m 0755 %{buildroot}/%{_sysconfdir}
%{__install} -d -m 0755 %{buildroot}/%{_localstatedir}/lib/%{wname}
%{__install} -d -m 0755 %{buildroot}/%{_localstatedir}/run
%{__install} -d -m 0755 %{buildroot}/%{webdir}


# Make distrib files
%{__make} install \
	DESTDIR=%{buildroot}

%{__install} -D -m 0644 %{wname}.cron \
    %{buildroot}/%{_sysconfdir}/cron.d/%{wname}
%{__install} -D -m 0644 httpd-%{wname}.conf \
    %{buildroot}/%{_sysconfdir}/httpd/conf.d/%{wname}.conf
%{__install} -D -m 0644 doc/%{wname}.1 \
    %{buildroot}/%{_mandir}/man1/%{wname}.1

# Remove unpackaged files.
rm -f `find %{buildroot}/%{_libdir}/perl*/ -name perllocal.pod -type f`
rm -f `find %{buildroot}/%{_libdir}/perl*/ -name .packlist -type f`

%clean
%{__rm} -rf %{buildroot}

%post
%{__cat} %{_docdir}/%{wname}-%{version}/README.RPM

%files
%defattr(0644,root,root,0755)
%doc Change* INSTALL README TODO README.RPM
%attr(0755,root,root) %{_bindir}/%{wname}
%attr(0755,root,root) %{_bindir}/r%{wname}
%attr(0755,root,root) %{_bindir}/%{wname}graph
%attr(0755,root,root) %{_bindir}/%{wname}jqgraph
%attr(0755,root,root) %{_bindir}/%{wname}warn
%attr(0644,root,root) %{_mandir}/man1/%{wname}.1.gz
%attr(0644,root,root) %{webdir}/sysusage-logo.png
%attr(0644,root,root) %{webdir}/sysusage.css
%attr(0644,root,root) %{webdir}/sysusage.js
%attr(0644,root,root) %{webdir}/sysusage_arrow.png
%attr(0644,root,root) %{webdir}/favicon.ico
%attr(0644,root,root) %{_libexecdir}/%{wname}/plugin-sample1.pl
%attr(0644,root,root) %{_libexecdir}/%{wname}/plugin-sample2.pl
%config(noreplace) %{_sysconfdir}/%{wname}.cfg
%config(noreplace) %{_sysconfdir}/cron.d/%{wname}
%config(noreplace) %{_sysconfdir}/httpd/conf.d/%{wname}.conf
%{perl_vendorlib}/%{uname}/Sar.pm
%dir %{_localstatedir}/lib/%{wname}
%dir %{_localstatedir}/run
%dir %{_libexecdir}/%{wname}
%dir %{webdir}

%changelog
* Tue Nov 24 2011 Gilles Darold <gilles@darold.net>
- Add new sysusagejqgraph and rsysusage perl script

* Fri Jan 15 2010 Gilles Darold <gilles@darold.net>
- Add new css, js and png files
- Update SysUsage site URL
- Remove unpackaged perl files (perllocal.pod and .packlist).
- Add display of post install message from README.RPM
- Update to 4.0

* Wed Nov 11 2009 Gilles Darold <gilles@darold.net>
- Update to 3.0
- Remove all spec fix as they are no more needed with this release
- Change install to used Makefile.PL capabilities
- Added all new files

* Sun Jul 26 2009 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 0:2.10-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_12_Mass_Rebuild

* Tue Jun  2 2009 Rob Myers <rmyers@fedoraproject.org> 0:2.10-1
- include many fixes from Jason Corley (Thanks!)
- update to 2.10
- update url to reflect upstream change to sourcefourge
- add requirement on vixie-cron
- remove source1 in favor of now included in tarball config file
- change to installing apache config commented out
- change description to most recent website blurb
- change README.Fedora to README.RPM (for EPEL)
- fix cronjob

* Wed Feb 25 2009 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 0:2.9-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_11_Mass_Rebuild

* Wed Oct 15 2008 Rob Myers <rob.myers@gtri.gatech.edu> 0:2.9-1
- update to 2.9
- move webdir /var/www/sysusage (resolves #465652)

* Wed Jul  2 2008 Rob Myers <rob.myers@gtri.gatech.edu> 0:2.6-4
- include missing versioned MODULE_COMPAT Requires (#453586)

* Thu Nov 15 2007 Rob Myers <rob.myers@gtri.gatech.edu> 0:2.6-3
- fix minor license issue
- add a default crontab entry
- add a default httpd configuration
- add README.Fedora

* Fri Nov  9 2007 Rob Myers <rob.myers@gtri.gatech.edu> 0:2.6-2
- seds really belong in prep

* Thu Nov  8 2007 Rob Myers <rob.myers@gtri.gatech.edu> 0:2.6-1
- move seds to build section
- remove perl requires
- update to 2.6

* Mon Jul 16 2007 Rob Myers <rob.myers@gtri.gatech.edu> 0:2.5-3
- define vname and wname in case this package should be renamed to
  perl-%%{uname}-%%{vname}

* Fri Jul 13 2007 Rob Myers <rob.myers@gtri.gatech.edu> 0:2.5-2
- change /var/db/sysusage to /var/lib/sysusage
- change perl_arch to perl_vendorlib to build noarch
- update license
- add dist tag
- misc spec changes and/or cleanups

* Fri Jul  6 2007 Jason Corley <jason.corley@gmail.com> 0:2.5-1
- first packaging attempt

