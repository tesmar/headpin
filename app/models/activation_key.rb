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
  extend ActiveModel::Naming

  attr_accessor :uuid, :name, :created, :pools, :poolCount, :owner, :subscriptions

  def initialize(json_hash=nil)
    @json_hash = super(json_hash)
    # rails doesn't like variables called id or type
    if @json_hash != {}
      @uuid = @json_hash["id"]
      @name = @json_hash["name"]
      @created = @json_hash["created"]
      @subscriptions = @json_hash["pools"] ? @json_hash["pools"] : []
      @poolCount = @subscriptions.size
      @owner = @json_hash["owner"]
    end
  end

  def self.retrieve_by_org(key)
    akeys = []
    JSON.parse(Candlepin::Proxy.get("/owners/#{key}/activation_keys")).each do |akey_json|
      akeys << ActivationKey.new(akey_json)
    end
    akeys
  end

  def self.retrieve(ak_id)
      ActivationKey.new(JSON.parse(Candlepin::Proxy.get("/activation_keys/#{ak_id}")))
  end

  def save
    if @json_hash['id']
      raise 'not implemented yet' #update
      #ret = JSON.parse(Candlepin::Proxy.put("/owners/#{username}",@json_hash.to_json))
    else
      #first save the thing, get an ID so you can post all the subs to it
      #possibility here that we have a duplicate named activation key, so let's check for that
      begin
          saved_key = JSON.parse(Candlepin::Proxy.post("/owners/#{owner.key}/activation_keys", {"name" => name}.to_json))
      rescue ::CandlepinError => e
        return false, e.message[1]
      end
      @json_hash['id'] = saved_key["id"]
      @uuid = saved_key["id"]

      subscriptions.each do |sub|
        JSON.parse(Candlepin::Proxy.post("/activation_keys/#{@uuid}/pools/#{sub}"))
      end
    end
    self
  end

  def destroy
    return Candlepin::Proxy.delete("/activation_keys/#{uuid}")
  end
end
