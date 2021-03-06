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

require 'util/password'

class User < Tableless

  attr_accessor :username, :superAdmin, :password

  def initialize(attrs={})
    @json_hash =  super(attrs)
    @superAdmin = TRUE_VALUES.include?(@json_hash["superAdmin"])
    @username = @json_hash["username"]
    @password = @json_hash["hashedPassword"]
  end

  def to_param
    username
  end

  def self.retrieve(user_id)
    User.new(JSON.parse(Candlepin::Proxy.get("/users/#{user_id}")))
  end

  def self.retrieve_all
    oj = JSON.parse(Candlepin::Proxy.get("/users"))
    users = []
    oj.each do |json_org|
      users << User.new(json_org)
    end
    users
  end

  def self.authenticate!(username, password)
    # Need to set a current user so that the proxy will use it
    # for the header.
    User.current= User.new({"username" => username})
    u = User.retrieve(username)
    # check if user exists
    return nil unless u
    # check if hash is valid
    return nil unless Password.check(password, u.password)
    u
  end

  def self.current
    @current ||= Thread.current[:request].env['warden'].user
  end

  def self.current=(o)
    @current = o
  end

  def superAdmin?
    @superAdmin == true
  end

  def update_attributes(attrs)
    attrs[:superAdmin]= TRUE_VALUES.include?(attrs[:superAdmin])
    super(attrs)
  end

  def cp_oauth_header
    { 'cp-user' => self.username }
  end

  def save
    if @json_hash['id']
      ret = JSON.parse(Candlepin::Proxy.put("/users/#{username}",@json_hash.to_json))
    else
      ret = JSON.parse(Candlepin::Proxy.post("/users",@json_hash.to_json))
      @json_hash['id'] = ret['id']
    end
    ret
  end

  def destroy
    Candlepin::Proxy.delete("/users/#{username}")
  end

  # Fake outs. May need to persist these values
  def page_size
    20
  end

  def roles
    Role.retrieve_all_by_user(username)
  end

  def update_roles(new_roles)
    old_roles = Role.retrieve_all_by_user(username).map(&:id)

    to_remove = old_roles - new_roles
    to_remove.each do |role_id|
      Candlepin::Proxy.delete( "/roles/#{role_id}/users/#{username}")
    end

    to_add = new_roles - old_roles
    to_add.each do |role_id|
      Candlepin::Proxy.post( "/roles/#{role_id}/users/#{username}", @json_hash.to_json)
    end

    return true
  end
end
