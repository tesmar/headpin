#
# Copyright 2011 Red Hat, Inc.
#
# This software is licensed to you under the GNU General Public
# License as published by the Free Software Foundation; either version
# 2 of the License (GPLv2) or (at your option) any later version.
# There is NO WARRANTY for this software, express or implied,
# including the implied warranties of MERCHANTABILITY,
# NON-INFRINGEMENT, or FITNESS FOR A PARTICULAR PURPOSE. You should
# have received a copy of GPLv2 along with this software; if not, see
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.

%global homedir %{_datarootdir}/%{name}
%global datadir %{_sharedstatedir}/%{name}
%global confdir deploy/common

Name:           headpin
Version:        0.0.5
Release:        1%{?dist}
Summary:        Front end for the candlepin engine

Group:          Applications/Internet
License:        GPLv2
URL:            http://www.candlepinproject.org
Source0:        %{name}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

Requires:       httpd
Requires:       mod_ssl
Requires:       openssl
Requires:       candlepin-tomcat6
Requires:       rubygems
Requires:       rubygem(rails) >= 3.0.10
Requires:       rubygem(multimap)
Requires:       rubygem(haml) >= 3.1.2
Requires:       rubygem(haml-rails)
Requires:       rubygem(json)
Requires:       rubygem(rest-client)
Requires:       rubygem(jammit)
Requires:       rubygem(rails_warden)
Requires:       rubygem(net-ldap)
Requires:       rubygem(compass) >= 0.11.5
Requires:       rubygem(compass-960-plugin) >= 0.10.4
Requires:       rubygem(capistrano)
Requires:       rubygem(oauth)
Requires:       rubygem(i18n_data) >= 0.2.6
Requires:       rubygem(gettext_i18n_rails)
Requires:       rubygem(simple-navigation) >= 3.3.4
Requires:       rubygem(sqlite3) 
Requires:       rubygem(pg)
Requires:       rubygem(scoped_search) >= 2.3.1
Requires:       rubygem(delayed_job) >= 2.1.4
Requires:       rubygem(daemons) >= 1.1.4
Requires:       rubygem(uuidtools)
Requires:       rubygem(thin)

# <workaround> for 714167 - undeclared dependencies (regin & multimap)
# TODO - uncomment the statement once we push patched actionpack to our EL6 repo
#%if 0%{?fedora} && 0%{?fedora} <= 15
Requires:       rubygem(regin)
#%endif
# </workaround>

Requires(pre):  shadow-utils
Requires(preun): chkconfig
Requires(preun): initscripts
Requires(post): chkconfig
Requires(postun): initscripts 

BuildRequires:  coreutils findutils sed
BuildRequires:  rubygems
BuildRequires:  rubygem-rake
BuildRequires:  rubygem(gettext)
BuildRequires:  rubygem(jammit)
BuildRequires:  rubygem(compass) >= 0.11.5
BuildRequires:  rubygem(compass-960-plugin) >= 0.10.4

BuildArch: noarch

%description
Provides a package for managing application life-cycle for Linux systems

%prep
%setup -q

%build
#configure Bundler
rm -f Gemfile.lock
sed -i '/@@@DEV_ONLY@@@/,$d' Gemfile
#compile SASS files
echo Compiling SASS files...
compass compile

#generate Rails JS/CSS/... assets
echo Generating Rails assets...
jammit

#create mo-files for L10n (since we miss build dependencies we can't use #rake gettext:pack)
echo Generating gettext files...
ruby -e 'require "rubygems"; require "gettext/tools"; GetText.create_mofiles(:po_root => "locale", :mo_root => "locale")'

#copy over the example file
mv config/%{name}.yml.example config/%{name}.yml

%install
rm -rf %{buildroot}
#prepare dir structure
install -d -m0755 %{buildroot}%{homedir}
install -d -m0755 %{buildroot}%{datadir}
install -d -m0755 %{buildroot}%{datadir}/tmp
install -d -m0755 %{buildroot}%{_sysconfdir}/%{name}
install -d -m0755 %{buildroot}%{_localstatedir}/log/%{name}

# clean the application directory before installing
[ -d tmp ] && rm -rf tmp

#copy the application to the target directory
mkdir .bundle
mv ./deploy/bundle-config .bundle/config
cp -R .bundle * %{buildroot}%{homedir}

#copy configs and other var files (will be all overwriten with symlinks)
install -m 644 config/%{name}.yml %{buildroot}%{_sysconfdir}/%{name}/%{name}.yml
#install -m 644 config/database.yml %{buildroot}%{_sysconfdir}/%{name}/database.yml
install -m 644 config/environments/production.rb %{buildroot}%{_sysconfdir}/%{name}/environment.rb

#copy init scripts and sysconfigs
install -Dp -m0644 %{confdir}/%{name}.sysconfig %{buildroot}%{_sysconfdir}/sysconfig/%{name}
install -Dp -m0755 %{confdir}/%{name}.init %{buildroot}%{_initddir}/%{name}
install -Dp -m0644 %{confdir}/%{name}.logrotate %{buildroot}%{_sysconfdir}/logrotate.d/%{name}
install -Dp -m0644 %{confdir}/%{name}.httpd.conf %{buildroot}%{_sysconfdir}/httpd/conf.d/%{name}.conf
install -Dp -m0644 %{confdir}/thin.yml %{buildroot}%{_sysconfdir}/%{name}/

#overwrite config files with symlinks to /etc/katello
ln -svf %{_sysconfdir}/%{name}/headpin.yml %{buildroot}%{homedir}/config/headpin.yml
#ln -svf %{_sysconfdir}/%{name}/database.yml %{buildroot}%{homedir}/config/database.yml
ln -svf %{_sysconfdir}/%{name}/environment.rb %{buildroot}%{homedir}/config/environments/production.rb

#create symlinks for some db/ files
#ln -svf %{datadir}/schema.rb %{buildroot}%{homedir}/db/schema.rb

#create symlinks for data
ln -sv %{_localstatedir}/log/%{name} %{buildroot}%{homedir}/log
ln -sv %{datadir}/tmp %{buildroot}%{homedir}/tmp

#create symlink for Gemfile.lock (it's being regenerated each start)
ln -svf %{datadir}/Gemfile.lock %{buildroot}%{homedir}/Gemfile.lock

#remove files which are not needed in the homedir
rm -rf %{buildroot}%{homedir}/README
rm -rf %{buildroot}%{homedir}/LICENSE
rm -rf %{buildroot}%{homedir}/doc
rm -rf %{buildroot}%{homedir}/deploy
rm -rf %{buildroot}%{homedir}/%{name}.spec
rm -f %{buildroot}%{homedir}/lib/tasks/.gitkeep
rm -f %{buildroot}%{homedir}/public/stylesheets/.gitkeep
rm -f %{buildroot}%{homedir}/vendor/plugins/.gitkeep
rm -f %{buildroot}%{homedir}/vendor/plugins/.gitignore
rm -f %{buildroot}%{homedir}/vendor/plugins/pullFromKatello.sh

#remove development tasks
rm %{buildroot}%{homedir}/lib/tasks/rcov.rake
rm %{buildroot}%{homedir}/lib/tasks/yard.rake
rm %{buildroot}%{homedir}/lib/tasks/hudson.rake


#correct permissions
find %{buildroot}%{homedir} -type d -print0 | xargs -0 chmod 755
find %{buildroot}%{homedir} -type f -print0 | xargs -0 chmod 644
chmod +x %{buildroot}%{homedir}/script/*

%clean
rm -rf %{buildroot}

%post
#%{homedir}/script/reset-oauth

#Add /etc/rc*.d links for the script
/sbin/chkconfig --add %{name}

%postun
if [ "$1" -ge "1" ] ; then
    /sbin/service %{name} condrestart >/dev/null 2>&1 || :
fi

%files
%defattr(-,root,root)
%doc README LICENSE doc/
%config(noreplace) %{_sysconfdir}/%{name}/%{name}.yml
%config %{_sysconfdir}/%{name}/thin.yml
%config %{_sysconfdir}/httpd/conf.d/headpin.conf
%config %{_sysconfdir}/%{name}/environment.rb
%config %{_sysconfdir}/logrotate.d/%{name}
%config(noreplace) %{_sysconfdir}/sysconfig/%{name}
%{_initddir}/%{name}
%{homedir}

%defattr(-, katello, katello)
%{_localstatedir}/log/%{name}
%{datadir}

%pre
# Add the "headpin" user and group
getent group %{name} >/dev/null || groupadd -r %{name}
getent passwd %{name} >/dev/null || \
    useradd -r -g %{name} -d %{homedir} -s /sbin/nologin -c "Headpin" %{name}
exit 0

%preun
if [ $1 -eq 0 ] ; then
    /sbin/service %{name} stop >/dev/null 2>&1
    /sbin/chkconfig --del %{name}
fi

%changelog
* Tue Sep 13 2011 Devan Goodwin <dgoodwin@rm-rf.ca> 0.0.5-1
- Initial tag.
