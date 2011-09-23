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

class Entitlement < Tableless
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :pool, :contractNumber, :endDate, :startDate, :consumed, :quantity, :cp_id

  def initialize(json_hash=nil)
    @json_hash = super(json_hash)
    # rails doesn't like variables called id or type

    if @json_hash != {}
      #convert the array of hashes into a hash you can access by name
      @pool = Subscription.retrieve(@json_hash["pool"]["id"])
      @startDate = DateTime.parse(@json_hash["startDate"])
      @endDate= DateTime.parse(@json_hash["endDate"])
      @consumed = @json_hash["consumed"].to_i
      @quantity = @json_hash["quantity"].to_i
      @contractNumber = @json_hash["contractNumber"]
      @cp_id = @json_hash["id"]
    end
    Rails.logger.ap "NEW Entitlement FROM CANDLEPIN JSON:::::::::::::"
    Rails.logger.ap self
  end

  def self.retrieve_all(consumer_id)
    entitlements = []
    JSON.parse(Candlepin::Proxy.get("/consumers/#{consumer_id}/entitlements")).each do |json_sub|
      begin
        entitlements << Entitlement.new(json_sub)
      rescue Exception => e
        Rails.logger.error "Unrecognized Entitlement: " + json_sub.to_s
        raise "Unrecognized Entitlement: " + json_sub.to_s + " " + e.to_s
      end
    end
    entitlements
  end

  def self.retrieve(ent_id)
    oj = nil
    begin
      oj = JSON.parse(Candlepin::Proxy.get("/entitlements/#{ent_id}"))
      return Entitlement.new(oj)
    rescue Exception => e
      Rails.logger.error "Unrecognized  Entitlement: " + oj.to_s
      raise "Unrecognized Entitlement: " + oj.to_s + "\n" + e.to_s
    end
  end
end
