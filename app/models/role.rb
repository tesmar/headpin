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

class Role < Tableless

  attr_accessor :name, :users, :permissions

  def initialize(json_hash=nil)
    @json_hash = (json_hash ||= {})
    # rails doesn't like variables called id or type
    if @json_hash != {}
      @name = @json_hash["name"]
      @users = @json_hash["users"].map { |u| User.new(u)}
      @permissions = @json_hash["permissions"].map { |p| Permission.new(p)}
    end
  end

  def self.retrieve(r_id)
    role = nil
    begin
      json_role = JSON.parse(Candlepin::Proxy.get("/roles/#{r_id}"))
      role = Role.new(json_role)
    rescue Exception => e
      Rails.logger.error "Unrecognized Role: " + json_role.to_s
      raise "Unrecognized Role: " + json_role.to_s + "\n" + e.to_s
    end
    role
  end

  def self.retrieve_all
    roles = []
    begin
      json_roles = JSON.parse(Candlepin::Proxy.get("/roles"))
      json_roles.each do |json_role|
        roles << Role.new(json_role)
      end
    rescue Exception => e
      Rails.logger.error "Unrecognized Role: " + json_roles.to_s
      raise "Unrecognized Role: " + json_roles.to_s + "\n" + e.to_s
    end
    roles
  end

  def self.retrieve_all_by_user(key)
    roles = []
    begin
      json_roles = JSON.parse(Candlepin::Proxy.get("/users/#{key}/roles"))
      json_roles.each do |json_role|
        roles << Role.new(json_role)
      end
    rescue Exception => e
      Rails.logger.error "Unrecognized Role: " + json_roles.to_s
      raise "Unrecognized Role: " + json_roles.to_s + "\n" + e.to_s
    end
    roles
  end

  def users_count
    users.count()
  end

  def add_user(user)
    Candlepin::Proxy.post("/roles/#{id}/users/#{user.username}")
  end

  def remove_user(user)
    Candlepin::Proxy.delete( "/roles/#{id}/users/#{user.username}")
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
