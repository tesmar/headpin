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

class Organization < Tableless
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  validates_presence_of :key
  validates_format_of :displayName,
    :with => /\A[^\/#]*\Z/,
    :message => _("cannot contain / or #")

  attr_accessor :key, :displayName, :org_id
  alias :org_key= :key=
  alias :org_key :key

  def initialize(json_hash=nil)
    @json_hash = (json_hash ||= {})
    # rails doesn't like variables called id or type
    if @json_hash != {}
      @key = @json_hash["key"]
      @org_id = @json_hash["id"]
      @displayName = @json_hash["displayName"]
    end
    Rails.logger.ap "NEW ORG FROM CANDLEPIN JSON:::::::::::::"
    Rails.logger.ap self
  end

  def self.retrieve(owner_id)
    oj = nil
    begin
      oj = JSON.parse(Candlepin::Proxy.get("/owners/#{owner_id}"))
      return Organization.new(oj)
    rescue Exception => e
      Rails.logger.error "Unrecognized Srg: " + oj.to_s
      raise "Unrecognized Org: " + oj.to_s + "\n" + e.to_s
    end
  end

  def self.retrieve_by_user(username)
    oj = JSON.parse(Candlepin::Proxy.get("/users/#{username}/owners"))
    orgs = []
    oj.each do |json_org|
      begin
        orgs << Organization.new(json_org)
      rescue Exception => e
        Rails.logger.error "Unrecognized Org: " + oj.to_s
        raise "Unrecognized Org: " + oj.to_s + "\n" + e.to_s
      end
    end
    orgs
  end

  # ActiveResource assumes anything with an ID is a pre-existing
  # resource, ID in our case is key, and key is manually assigned at creation,
  # so we must override the new check to force active record to persist our
  # new org.
  def new?
    org_id.nil?
  end

  def info
    # TODO: hardcoded app prefix
    @info ||= JSON.parse(Candlepin::Proxy.get("/owners/#{key}/info"))
    @info
  end

  def system_count
    info['consumerGuestCounts']['physical']
  end

  def guest_count
    info['consumerGuestCounts']['guest']
  end

  def subscriptions
    @subscriptions ||= Subscription.retrieve_all( { :owner => @cp_id})
  end

  def total_consumer_stats
    @total_consumer_stats ||= Statistic.retrieve_all_by_org(@key, :type => Statistic::TOTALCONSUMERS)
  end

  def total_subscription_stats
    @total_consumer_stats ||= Statistic.retrieve_all_by_org(@key, :type => Statistic::TOTALSUBSCRIPTIONCOUNT)
  end

  def subscription_consumed_stats
    @subscription_consumed_stats ||=
      Statistic.retrieve_all_by_org(@key,
                            :type => Statistic::TOTALSUBSCRIPTIONCONSUMED).select do |stat|
      stat.valueType = "RAW"
                            end
  end

  def subscription_percent_consumed_stats
    @subscription_percent_consumed_stats ||=
      Statistic.retrieve_all_by_org(@key,
                            :type => Statistic::TOTALSUBSCRIPTIONCONSUMED).select do |stat|
      stat.valueType = "PERCENTAGECONSUMED"
                            end
  end

  # TODO: Fetching all subscriptions for the owner here (active today). This
  # could be optimized by adding new info to OwnerInfo in Candlepin.
  def subscriptions_summary
    @subscription_summary ||=
      { :available => subscriptions.inject(0) do |quantity, sub|
      quantity += sub.quantity
      end,
        :used => subscriptions.inject(0) do |consumed, sub|
        consumed += sub.consumed
        end
    }
  end


  def to_json(options = {})
    options.merge(:except => [:id])
    super(options)
  end

  def id
    key
  end
end
