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

class System < Tableless
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :name, :entitlementCount, :uuid, :owner_key
  attr_accessor :created, :lastCheckin, :username, :facts, :owner

  def initialize(json_hash=nil)
    @json_hash = super(json_hash)
    #extra fields specific to systems
    if @json_hash != {}
      @name ||= @json_hash["name"]
      @owner_key = @json_hash["owner"]["key"]
      @lastCheckin = @json_hash["owner"]["lastCheckin"]
      @username = @json_hash["owner"]["username"]
      @created = Date.parse(@json_hash["created"])
      @owner = @json_hash["owner"]
      @facts = @json_hash["facts"]
      @entitlementCount = @json_hash["entitlementCount"]

      #@consumed_entitlements = []
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
    params = {"pool" => pool_id, "quantity" => 1}
    path = "/consumers/#{uuid}/entitlements?" + params.to_query
    results = JSON.parse(Candlepin::Proxy.post(path))[0]
    Entitlement.new(results)
  end

  def unbind(ent_id)
    # TODO: hardcoded app prefix
    path = "/consumers/#{uuid}/entitlements/#{ent_id}"
    resp = Candlepin::Proxy.delete(path) #returns an empty string
    resp == "" ? true : false
  end


  def entitlement_status
    return _("Unknown") unless @facts.blank?
    status = @facts['system.entitlements_valid']
    return _("Unknown") if status.nil?
    return _("Valid") if status
    return _("Invalid")
  end

  def create(new_system_info = {})
    #we need the org_id to create the consumer 
    #options[:query] = { :username => auth_info[:user], :owner => user.org_id } 
    new_system_info = {"type" => "system", "arch" => "i386", "name" => "System1test"}
    #options[:body] = @json_hash.to_json
    return Candlepin::Proxy.post('/consumers?' + {:owner => @owner_key, :username => @owner_key }.to_query, new_system_info.to_json)
  end
end

