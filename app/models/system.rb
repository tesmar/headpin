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

require 'json'

class System < Base
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :name, :entitlementCount, :entitlement_status, :uuid, :owner_key
  attr_accessor :created, :lastCheckin, :username, :facts

  def initialize(json_hash=nil)
    @json_hash = super(json_hash)
    #extra fields specific to systems
    if @json_hash != {}
      @name ||= @json_hash["name"]
      @owner_key = @json_hash["owner"]["key"]
      @lastCheckin = @json_hash["owner"]["lastCheckin"]
      @username = @json_hash["owner"]["username"]
      @created = Date.parse(@json_hash["created"])
      @facts = @json_hash["facts"].to_a.sort
      #@consumed_entitlements = []
      #TEMPORARY TO GET VIEW TO WORK
      @entitlement_status = "good"
      @entitlement_count = 0
      @entitlementCount = 5
      #if json_hash["entitlements"] != nil
      #  json_hash["entitlements"].each do |e|
          #@consumed_entitlements << Entitlement.new(e)
          #@entitlement_count = @entitlement_count + e["quantity"]
      #  end
      #@entitlements = consumed_entitlements
    end
    Rails.logger.ap "NEW SYSTEM FROM CANDLEPIN JSON:::::::::::::"
    Rails.logger.ap self
  end

  def self.retrieve(uuid)
    sj = nil
    begin
      sj = JSON.parse(Candlepin::Proxy.get("/consumers/#{uuid}", {:type => "system"}))
      return System.new(sj)
    rescue Exception => e
      Rails.logger.error "Unrecognized System: " + sj.to_s
      raise "Unrecognized System: " + sj.to_s + "\n" + e.to_s
    end
  end

  def self.retrieve_all
    systems = []
    JSON.parse(Candlepin::Proxy.get('/consumers', {:type => "system"})).each do |json_system|
      begin
        systems << System.new(json_system)
      rescue Exception => e
        Rails.logger.error "Unrecognized System: " + json_system.to_s
      end
    end
    systems
  end

  def bind(pool_id)
    # TODO: hardcoded app prefix
    path = "/candlepin/consumers/#{uuid}/entitlements?pool=#{pool_id}"
    results = connection.post(path, "", Base.headers)
    attributes = JSON.parse(results.body)[0]
    ent = Entitlement.new(attributes)
    return ent
  end

  #def entitlement_status()
  #  status = facts.attributes['system.entitlements_valid']
  #  return _("Unknown") if status.nil?
  #  return _("Valid") if status
  #  return _("Invalid")
  #end

end

