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
Version:        0.0.7
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
Requires:       rubygem(awesome_print)
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
* Mon Sep 26 2011 Bryan Kearney <bkearney@redhat.com> 0.0.7-1
- Updating gem reuiqrements (tsmart@redhat.com)
- Merge branch 'master' of ssh://git.fedorahosted.org/git/headpin
  (tsmart@redhat.com)
- Fixed a small JS issue not causing the roles to work (tsmart@redhat.com)
- added update_subscriptions route back (thomasmckay@redhat.com)
- Removing permission file (tsmart@redhat.com)
- Adding teh katello favicon (tsmart@redhat.com)
- Roles and Permissions tests (tsmart@redhat.com)
- Fixing the Permissions add double click issue (tsmart@redhat.com)
- You can now view permissions and delete them (tsmart@redhat.com)
- You can now add permissions and view all the ones for your org. A few bugs
  exist like you have to double click to add a permission, you cannot view the
  details of a perm yet and you cannot edit/delete (tsmart@redhat.com)
- Now you can see all orgs when selecting perms (tsmart@redhat.com)
- Now can change the name of the role from the UI. THIS was annoying to track
  down as it was another piece of katello that was not properly ported over
  (tsmart@redhat.com)
- Now you can add and remove Roles (tsmart@redhat.com)
- Getting roles to initially show up in the second panel when you click on it
  (tsmart@redhat.com)
- Update the spec file (bkearney@redhat.com)
- Move headpin to rails 3.0.10. Makes headpin in line with katello
  (bkearney@redhat.com)
- copied systems/subscriptions tab from katello, replacing double tab style in
  headpin (thomasmckay@redhat.com)
- Ensure that you can view the successful import in the history
  (bkearney@redhat.com)
- roles display (abenari@redhat.com)
- Allow for no product attributes in arch (bkearney@redhat.com)
- corrected typo in showing product name (thomasmckay@redhat.com)
- cleaning up systems / subscriptions to properly subscribe and update after
  subscription (thomasmckay@redhat.com)
- Restoring proper system navigation (tsmart@redhat.com)
- Adding missing file (tsmart@redhat.com)
- CRUD for Systems + tests (tsmart@redhat.com)
- fixed panel close in new user (abenari@redhat.com)
- moved the code to katello style notices (abenari@redhat.com)
- fixed delete user (abenari@redhat.com)
- fixed create user (abenari@redhat.com)
- added to param that the navigation helper methods needs (abenari@redhat.com)
- moved active model includes into the base class (abenari@redhat.com)
- fixed users page navigation (abenari@redhat.com)
- renamed user_role to edit roles in user controller (abenari@redhat.com)
- added user save (abenari@redhat.com)
- added update attributes to the tabless class (abenari@redhat.com)
- moved activation_keys_controller_spec.rb into controllers/ where it belongs
  (thomasmckay@redhat.com)
- enable the graphs again (bkearney@redhat.com)
- fix some of the sub-panes which looked bad with the earlier stylin
  (bkearney@redhat.com)
- Merge branch 'master' of ssh://git.fedorahosted.org/git/headpin
  (bkearney@redhat.com)
- fixed hardcode reference to dashboard url in spec tests
  (thomasmckay@redhat.com)
- Merge branch 'master' of ssh://git.fedorahosted.org/git/headpin
  (bkearney@redhat.com)
- merge after pullFromKatello.sh (thomasmckay@redhat.com)
- Merge branch 'master' of ssh://git.fedorahosted.org/git/headpin
  (bkearney@redhat.com)
- Pass a prefix into two_pane list items now like katello does to avoid
  conflicts in html id values. (The user name admin was conflicting with the
  admin page.) (thomasmckay@redhat.com)
- roles and permissions updated to new tableless base (thomasmckay@redhat.com)
- Merge branch 'master' of ssh://git.fedorahosted.org/git/headpin
  (bkearney@redhat.com)
- Merge branch 'master' of ssh://git.fedorahosted.org/git/headpin
  (bkearney@redhat.com)
- Change the zanata server name (bkearney@redhat.com)
- updated Event and ImportRecord to tableless retrieve methods
  (thomasmckay@redhat.com)
- Renaming certificates zip to be that (tsmart@redhat.com)
- Merge branch 'master' of ssh://git.fedorahosted.org/git/headpin
  (tsmart@redhat.com)
- Adding test for cert zip download (tsmart@redhat.com)
- Bring over arrow icon, and fix the footer (bkearney@redhat.com)
- Knock off a few more navgation issues (bkearney@redhat.com)
- get the images back in for the tree view (bkearney@redhat.com)
- Basic nav is working (bkearney@redhat.com)
- logout is working (bkearney@redhat.com)
- Basic login page working (bkearney@redhat.com)
- Add support for the RAILS_RELATIVE_URL_ROOT env variable
  (bkearney@redhat.com)
- Add the thin gem (bkearney@redhat.com)
- Merge in the tito branhc (bkearney@redhat.com)
- Fixing a few stragglign things while leaving updates over rest-client for a
  future commit (tsmart@redhat.com)
- these are working versions of all gems (tsmart@redhat.com)
- removing extra debug lines (tsmart@redhat.com)
- Merging master into rest-client (tsmart@redhat.com)
- Fixing up tests to work with new Candlpin::Proxy layer (tsmart@redhat.com)
- Fixed bind and unbind for systems as well as a little system cleanup and
  entitlement work (tsmart@redhat.com)
- Letting Errors bubble up for now until we implement proper site-wide error
  catching (tsmart@redhat.com)
- reverted include background-image commit and fixed all compass compilation
  warning (abenari@redhat.com)
- added some js files from katello (abenari@redhat.com)
- fixed login page (abenari@redhat.com)
- updated javascripts to kt lateset (abenari@redhat.com)
- adding root url (abenari@redhat.com)
- add support for adding and removing users from role (abenari@redhat.com)
- moved operations scss content into admin.scss (abenari@redhat.com)
- removed comments. (abenari@redhat.com)
- renamed user to logged_in_user because user is ambiguaos (abenari@redhat.com)
- update user roles workaround (abenari@redhat.com)
- updated to katello latest (abenari@redhat.com)
- initial support for maneging user roles. (update user_roles doesn't work yet,
  pending bz#735034) (abenari@redhat.com)
- initial commit (abenari@redhat.com)
- Removing dependence upon base and moving over to tableless
  (tsmart@redhat.com)
- Have now moved most(if not all) of the app off of ACtiveResource ... much
  cleanup to do but it is working (tsmart@redhat.com)
- Fixing Activation Keys, USers, and Orgs (calls to candlepin)
  (tsmart@redhat.com)
- Ripped out active record for real this time and have user login + the systems
  page working. Started refactoring the rest_client initialization into
  tableless (tsmart@redhat.com)
- First run at replacing Active Resource with Rest-Client. Lot of cleanup to
  do. Want to create a master 'tableless' class that all models will inherit
  which will define initialiaze and find(). TODO later. Also the dashboard is
  broken and the subscriptions page is slow. Will optimize and fix the 1 or 2
  remaining calls when I return from vacation and add tests (tsmart@redhat.com)

* Mon Sep 26 2011 Bryan Kearney <bkearney@redhat.com>
- Updating gem reuiqrements (tsmart@redhat.com)
- Merge branch 'master' of ssh://git.fedorahosted.org/git/headpin
  (tsmart@redhat.com)
- Fixed a small JS issue not causing the roles to work (tsmart@redhat.com)
- added update_subscriptions route back (thomasmckay@redhat.com)
- Removing permission file (tsmart@redhat.com)
- Adding teh katello favicon (tsmart@redhat.com)
- Roles and Permissions tests (tsmart@redhat.com)
- Fixing the Permissions add double click issue (tsmart@redhat.com)
- You can now view permissions and delete them (tsmart@redhat.com)
- You can now add permissions and view all the ones for your org. A few bugs
  exist like you have to double click to add a permission, you cannot view the
  details of a perm yet and you cannot edit/delete (tsmart@redhat.com)
- Now you can see all orgs when selecting perms (tsmart@redhat.com)
- Now can change the name of the role from the UI. THIS was annoying to track
  down as it was another piece of katello that was not properly ported over
  (tsmart@redhat.com)
- Now you can add and remove Roles (tsmart@redhat.com)
- Getting roles to initially show up in the second panel when you click on it
  (tsmart@redhat.com)
- Update the spec file (bkearney@redhat.com)
- Move headpin to rails 3.0.10. Makes headpin in line with katello
  (bkearney@redhat.com)
- copied systems/subscriptions tab from katello, replacing double tab style in
  headpin (thomasmckay@redhat.com)
- Ensure that you can view the successful import in the history
  (bkearney@redhat.com)
- roles display (abenari@redhat.com)
- Allow for no product attributes in arch (bkearney@redhat.com)
- corrected typo in showing product name (thomasmckay@redhat.com)
- cleaning up systems / subscriptions to properly subscribe and update after
  subscription (thomasmckay@redhat.com)
- Restoring proper system navigation (tsmart@redhat.com)
- Adding missing file (tsmart@redhat.com)
- CRUD for Systems + tests (tsmart@redhat.com)
- fixed panel close in new user (abenari@redhat.com)
- moved the code to katello style notices (abenari@redhat.com)
- fixed delete user (abenari@redhat.com)
- fixed create user (abenari@redhat.com)
- added to param that the navigation helper methods needs (abenari@redhat.com)
- moved active model includes into the base class (abenari@redhat.com)
- fixed users page navigation (abenari@redhat.com)
- renamed user_role to edit roles in user controller (abenari@redhat.com)
- added user save (abenari@redhat.com)
- added update attributes to the tabless class (abenari@redhat.com)
- moved activation_keys_controller_spec.rb into controllers/ where it belongs
  (thomasmckay@redhat.com)
- enable the graphs again (bkearney@redhat.com)
- fix some of the sub-panes which looked bad with the earlier stylin
  (bkearney@redhat.com)
- Merge branch 'master' of ssh://git.fedorahosted.org/git/headpin
  (bkearney@redhat.com)
- fixed hardcode reference to dashboard url in spec tests
  (thomasmckay@redhat.com)
- Merge branch 'master' of ssh://git.fedorahosted.org/git/headpin
  (bkearney@redhat.com)
- merge after pullFromKatello.sh (thomasmckay@redhat.com)
- Merge branch 'master' of ssh://git.fedorahosted.org/git/headpin
  (bkearney@redhat.com)
- Pass a prefix into two_pane list items now like katello does to avoid
  conflicts in html id values. (The user name admin was conflicting with the
  admin page.) (thomasmckay@redhat.com)
- roles and permissions updated to new tableless base (thomasmckay@redhat.com)
- Merge branch 'master' of ssh://git.fedorahosted.org/git/headpin
  (bkearney@redhat.com)
- Merge branch 'master' of ssh://git.fedorahosted.org/git/headpin
  (bkearney@redhat.com)
- Change the zanata server name (bkearney@redhat.com)
- updated Event and ImportRecord to tableless retrieve methods
  (thomasmckay@redhat.com)
- Renaming certificates zip to be that (tsmart@redhat.com)
- Merge branch 'master' of ssh://git.fedorahosted.org/git/headpin
  (tsmart@redhat.com)
- Adding test for cert zip download (tsmart@redhat.com)
- Bring over arrow icon, and fix the footer (bkearney@redhat.com)
- Knock off a few more navgation issues (bkearney@redhat.com)
- get the images back in for the tree view (bkearney@redhat.com)
- Basic nav is working (bkearney@redhat.com)
- logout is working (bkearney@redhat.com)
- Basic login page working (bkearney@redhat.com)
- Add support for the RAILS_RELATIVE_URL_ROOT env variable
  (bkearney@redhat.com)
- Add the thin gem (bkearney@redhat.com)
- Merge in the tito branhc (bkearney@redhat.com)
- Fixing a few stragglign things while leaving updates over rest-client for a
  future commit (tsmart@redhat.com)
- these are working versions of all gems (tsmart@redhat.com)
- removing extra debug lines (tsmart@redhat.com)
- Merging master into rest-client (tsmart@redhat.com)
- Fixing up tests to work with new Candlpin::Proxy layer (tsmart@redhat.com)
- Fixed bind and unbind for systems as well as a little system cleanup and
  entitlement work (tsmart@redhat.com)
- Letting Errors bubble up for now until we implement proper site-wide error
  catching (tsmart@redhat.com)
- reverted include background-image commit and fixed all compass compilation
  warning (abenari@redhat.com)
- added some js files from katello (abenari@redhat.com)
- fixed login page (abenari@redhat.com)
- updated javascripts to kt lateset (abenari@redhat.com)
- adding root url (abenari@redhat.com)
- add support for adding and removing users from role (abenari@redhat.com)
- moved operations scss content into admin.scss (abenari@redhat.com)
- removed comments. (abenari@redhat.com)
- renamed user to logged_in_user because user is ambiguaos (abenari@redhat.com)
- update user roles workaround (abenari@redhat.com)
- updated to katello latest (abenari@redhat.com)
- initial support for maneging user roles. (update user_roles doesn't work yet,
  pending bz#735034) (abenari@redhat.com)
- initial commit (abenari@redhat.com)
- Removing dependence upon base and moving over to tableless
  (tsmart@redhat.com)
- Have now moved most(if not all) of the app off of ACtiveResource ... much
  cleanup to do but it is working (tsmart@redhat.com)
- Fixing Activation Keys, USers, and Orgs (calls to candlepin)
  (tsmart@redhat.com)
- Ripped out active record for real this time and have user login + the systems
  page working. Started refactoring the rest_client initialization into
  tableless (tsmart@redhat.com)
- First run at replacing Active Resource with Rest-Client. Lot of cleanup to
  do. Want to create a master 'tableless' class that all models will inherit
  which will define initialiaze and find(). TODO later. Also the dashboard is
  broken and the subscriptions page is slow. Will optimize and fix the 1 or 2
  remaining calls when I return from vacation and add tests (tsmart@redhat.com)

* Tue Sep 13 2011 Devan Goodwin <dgoodwin@rm-rf.ca> 0.0.5-1
- Initial tag.
