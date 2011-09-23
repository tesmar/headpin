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

  class << self
    def architectures
      { 'x86' => :'i386', 'Itanium' => :'ia64', 'x86_64' => :x86_64, 'PowerPC' => :ppc,
      'IBM S/390' => :s390, 'IBM System z' => :s390x,  'SPARC Solaris' => :'sparc64' }
    end

    def virtualized
      { "physical" => N_("Physical"), "virtualized" => N_("Virtual") }
    end
  end

  attr_accessor :name, :entitlementCount, :uuid, :owner_key
  attr_accessor :created, :lastCheckin, :username, :facts, :owner
  attr_accessor :arch, :sockets, :virtualized

  def initialize(json_hash=nil)
    @json_hash = super(json_hash)
    #extra fields specific to systems
    if @json_hash != {}
      @name ||= @json_hash["name"]
      @owner_key = @json_hash["owner"]["key"]
      @lastCheckin = @json_hash["owner"]["lastCheckin"]
      @username = @json_hash["owner"]["username"]
      @created = DateTime.parse(@json_hash["created"])
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

  def bind(pool_id, quantity=1)
    begin
      # TODO: hardcoded app prefix
      params = {"pool" => pool_id, "quantity" => quantity}
      path = "/consumers/#{uuid}/entitlements?" + params.to_query
      results = JSON.parse(Candlepin::Proxy.post(path))[0]
      Entitlement.new(results)
    rescue Exception => error
      x = JSON.parse(error.response.to_s)
      raise "Subscribe failed - #{x["displayMessage"]}"
    end
  end

  def unbind(ent_id, quantity=1)
    begin
      # TODO: hardcoded app prefix
      params = {"quantity" => quantity}
      path = "/consumers/#{uuid}/entitlements/#{ent_id}?" + params.to_query
      resp = Candlepin::Proxy.delete(path) #returns an empty string
      resp == "" ? true : false
    rescue Exception => error
      x = JSON.parse(error.response.to_s)
      raise "Unsubscribe failed - #{x["displayMessage"]}"
    end
  end


  def entitlement_status
    return _("Unknown") unless @facts.blank?
    status = @facts['system.entitlements_valid']
    return _("Unknown") if status.nil?
    return _("Valid") if status
    return _("Invalid")
  end

  def update(new_values)

    begin
      update_json = Candlepin::Consumer.update(uuid,new_values) #either :facts => or just straight values
      #update_json = JSON.parse(Candlepin::Proxy.put("/consumers/#{uuid}", new_values, uuid))
      return update_json
    rescue Exception => e
      Rails.logger.error "Error updating System: " + update_json.to_s
      raise "Error updating System: " + update_json.to_s + "\n" + e.to_s
    end
  end

  def create
    new_system_info = {"type" => "system",
                       "name" => name,
                        :facts => {"uname.machine" => arch,
                                   "cpu.cpu_socket(s)" => sockets,
                                   "virt.is_guest" => (virtualized == 'virtual'),
                                   "network.hostname" => name
                                   }}
    f = Candlepin::Proxy.post('/consumers?' + {:owner => owner.key, :username => owner.key }.to_query, new_system_info.to_json)
    System.new(JSON.parse(f))
  end

  def destroy
    return Candlepin::Proxy.delete("/consumers/#{uuid}")
  end

  # Stubs carried over from Katello

  def editable?
    true
  end
end

