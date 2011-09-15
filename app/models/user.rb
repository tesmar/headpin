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

class User < Tableless
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :username, :superAdmin

  def initialize(attrs={})
    @json_hash =  super(attrs)
    @superAdmin = TRUE_VALUES.include?(@json_hash["superAdmin"])
    @username = @json_hash["username"]
    Rails.logger.ap "NEW USER FROM CANDLEPIN JSON:::::::::::::"
    Rails.logger.ap self
  end

  def self.retrieve(user_id)
    oj = nil
    begin
      oj = JSON.parse(Candlepin::Proxy.get("/users/#{user_id}"))
      return User.new(oj)
    rescue Exception => e
      Rails.logger.error "Unrecognized USer: " + oj.to_s
      raise "Unrecognized User: " + oj.to_s + "\n" + e.to_s
    end
  end

  def self.retrieve_all
    oj = JSON.parse(Candlepin::Proxy.get("/users"))
    users = []
    oj.each do |json_org|
      begin
        users << User.new(json_org)
      rescue Exception => e
        Rails.logger.error "Unrecognized User: " + oj.to_s
        raise "Unrecognized User: " + oj.to_s + "\n" + e.to_s
      end
    end
    users
  end

  def self.current
    @current ||= Thread.current[:request].env['warden'].user
  end

  def self.current=(o)
    @current = o
  end

  def to_param
    username
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
      connection.delete( "#{AppConfig.candlepin.prefix}/roles/#{role_id}/users/#{username}")
    end

    to_add = new_roles - old_roles
    to_add.each do |role_id|
      connection.post( "#{AppConfig.candlepin.prefix}/roles/#{role_id}/users/#{username}")
    end

    return true
  end
end
