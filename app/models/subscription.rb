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

class Subscription < Base

  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :name, :displayName, :product, :uuid, :owner
  attr_accessor :consumed, :quantity, :contractNumber, :startDate, :endDate

  # Our subscription is actually a pool in the Candlepin API:
  def initialize(json_hash=nil)
    @json_hash = (json_hash ||= {})
    # rails doesn't like variables called id or type
    if @json_hash != {}
      @name = @json_hash["name"]
      @uuid = @json_hash["id"]
      @displayName = @json_hash["displayName"]
      @product = @json_hash["product"]
      @owner = @json_hash["owner"]
      @startDate = DateTime.parse(@json_hash["startDate"])
      @endDate= DateTime.parse(@json_hash["endDate"])
      @consumed = @json_hash["consumed"]
      @quantity = @json_hash["quantity"]
      @contractNumber = @json_hash["contractNumber"]
    end
  end

  def self.retrieve_all(optional_params = {})
    subs = []
    JSON.parse(Candlepin::Proxy.get('/subscriptions', optional_params)).each do |json_sub|
      begin
        subs << Subscription.new(json_sub)
      rescue Exception => e
        Rails.logger.error "Unrecognized Subscription: " + json_sub.to_s
        raise "Unrecognized Subscription: " + json_sub.to_s + " " + e.to_s
      end
    end
    subs
  end

  def consumed_stats
    @stats = Statistic.retrieve_all_by_org(self.owner["key"], :type => Statistic::PERPOOL, :reference => self.uuid)
    @stats.select do |stat|
      stat.valueType == "CONSUMED"
    end
  end

end
