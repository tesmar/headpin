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

class ActivationKey < Tableless
  include ActiveModel::Validations
  include ActiveModel::Conversion

  attr_accessor :uuid, :name, :created, :pools, :poolCount, :owner

  def initialize(json_hash=nil)
    @json_hash = (json_hash ||= {})
    # rails doesn't like variables called id or type
    if @json_hash != {}
      @uuid = @json_hash["id"]
      @name = @json_hash["name"]
      @created = @json_hash["created"]
      @pools = @json_hash["pools"]
      @poolCount = @pools.size
      @owner = @json_hash["owner"]
    end
    Rails.logger.ap "NEW ACTIVATION KEY FROM CANDLEPIN JSON:::::::::::::"
    Rails.logger.ap self
  end
  extend ActiveModel::Naming

  def self.retrieve_by_org(key)
    oj = nil
    akeys = []
    begin
      oj = JSON.parse(Candlepin::Proxy.get("/owners/#{key}/activation_keys"))
      oj.each do |akey_json|
        akeys << ActivationKey.new(akey_json)
      end
      return akeys
    rescue Exception => e
      Rails.logger.error "Unrecognized Activation Key: " + oj.to_s
      raise "Unrecognized Activation Key: " + oj.to_s + "\n" + e.to_s
    end
    oj
  end

  def self.retrieve(ak_id)
    oj = nil
    begin
      oj = JSON.parse(Candlepin::Proxy.get("/activation_keys/#{ak_id}"))
      return ActivationKey.new(oj)
    rescue Exception => e
      Rails.logger.error "Unrecognized Activation Key: " + oj.to_s
      raise "Unrecognized Activation Key: " + oj.to_s + "\n" + e.to_s
    end
  end
end
