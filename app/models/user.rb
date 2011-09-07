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

class User < Base
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  def to_param
    username
  end
  
  def initialize(attrs={})
    attrs[:superAdmin]= TRUE_VALUES.include?(attrs[:superAdmin])
    super(attrs)
  end

  def update_attributes(attrs)
    attrs[:superAdmin]= TRUE_VALUES.include?(attrs[:superAdmin])
    super(attrs)
  end

  def cp_oauth_header
    { 'cp-user' => self.username }
  end

  schema do
    string 'id', 'username', 'password', "superAdmin"
  end

  # Fake outs. May need to persist these values
  def page_size
    20
  end

  def roles
    Role.find(:all, :from => "#{AppConfig.candlepin.prefix}/users/#{username}/roles")
  end

  def update_roles(new_roles)
    old_roles = Role.find(:all, :from => "#{AppConfig.candlepin.prefix}/users/#{username}/roles").map(&:id)

    to_remove = old_roles - new_roles
    to_remove.each do |role_id|
      connection.delete( "#{AppConfig.candlepin.prefix}/roles/#{role_id}/users/#{username}")
    end

    to_add = new_roles - old_roles
    to_add.each do |role_id|
      connection.post( "#{AppConfig.candlepin.prefix}/roles/#{role_id}/users/#{username}")
    end
    
    return true
  end
end
