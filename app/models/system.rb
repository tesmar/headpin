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
  attr_accessor :arch, :sockets, :virtualized, :products

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
      @products = @json_hash['installedProducts']
    end
  end

  def self.retrieve(uuid)
    System.new(JSON.parse(Candlepin::Proxy.get("/consumers/#{uuid}", {:type => "system"})))
  end

  def self.retrieve_all
    systems = []
    JSON.parse(Candlepin::Proxy.get('/consumers', {:type => "system"})).each do |json_system|
      systems << System.new(json_system)
    end
    systems
  end

  def bind(pool_id, quantity=1)
    # TODO: hardcoded app prefix
    params = {"pool" => pool_id, "quantity" => quantity}
    path = "/consumers/#{uuid}/entitlements?" + params.to_query
    results = JSON.parse(Candlepin::Proxy.post(path))[0]
    Entitlement.new(results)
  end

  def unbind(ent_id, quantity=1)
    # TODO: hardcoded app prefix
    params = {"quantity" => quantity}
    path = "/consumers/#{uuid}/entitlements/#{ent_id}?" + params.to_query
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

  def update(new_values)
    Candlepin::Consumer.update(uuid,new_values) #either :facts => or just straight values
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

