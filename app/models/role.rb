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

class Role < Base
  include ActiveModel::Conversion
  extend ActiveModel::Naming



  def users_count
    users.count()
  end

  def add_user(user)
    connection.post( "#{AppConfig.candlepin.prefix}/roles/#{id}/users/#{user.username}")
  end
  
  def remove_user(user)
    connection.delete( "#{AppConfig.candlepin.prefix}/roles/#{id}/users/#{user.username}")
  end

  #permissions
  def self.creatable?
   true
  end

  def self.editable?
   true
  end

  def self.deletable?
    true
  end

  def self.any_readable?
    true
  end

  def self.readable?
    Role.any_readable?
  end

  def summary
    perms = permissions.collect{|perm| perm.to_abbrev_text}.join("\n")
    "Role: #{name}\nPermissions:\n#{perms}"
  end

  def self.list_verbs global = false
    {
    :create => N_("Create Roles"),
    :read => N_("Access Roles"),
    :update => N_("Update Roles"),
    :delete => N_("Delete Roles"),
    }.with_indifferent_access
  end

  def self.no_tag_verbs
    [:create]
  end

  private
  READ_PERM_VERBS = [:read,:update, :create,:delete]

end
