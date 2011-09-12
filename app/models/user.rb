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
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :username

  def initialize(attrs={})
    @json_hash =  super(attrs)
    @superAdmin = TRUE_VALUES.include?(@json_hash["superAdmin"])
    @username = @json_hash["username"]
    Rails.logger.ap "NEW USER FROM CANDLEPIN JSON:::::::::::::"
    Rails.logger.ap self
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

#  schema do
#    string 'id', 'username', 'password', "superAdmin"
#  end

  # Fake outs. May need to persist these values
  def page_size
    20
  end
end
