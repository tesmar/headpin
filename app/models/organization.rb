class Organization < Base
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  # Candlepin calls this resource an owner:
  self.element_name = "owner"

  schema do
    string 'key', 'displayName'
  end

  validates_presence_of :key
  validates_format_of :displayName,
    :with => /\A[^\/#]*\Z/,
    :message => _("cannot contain / or #")

  def org_id
    @attributes[:id]
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
    path = "/candlepin/owners/#{key}/info"
    @info ||= connection.get(path, Base.headers)
    @info
  end

  def system_count
    info['consumerGuestCounts']['physical']
  end
  
  def guest_count
    info['consumerGuestCounts']['guest']
  end  

  def subscriptions
    @subscriptions ||= Subscription.find(:all, :params => { :owner => org_id })
  end
  
  def total_consumer_stats
    @total_consumer_stats ||= Statistic.find_for_org(self.key, :type => Statistic::TOTALCONSUMERS)
  end
  
  def total_subscription_stats
    @total_consumer_stats ||= Statistic.find_for_org(self.key, :type => Statistic::TOTALSUBSCRIPTIONCOUNT)
  end  
  
  def subscription_consumed_stats
    @subscription_consumed_stats ||= 
      Statistic.find_for_org(self.key, 
        :type => Statistic::TOTALSUBSCRIPTIONCONSUMED).select do |stat|
          stat.valueType = "RAW"
        end
  end  
  
  def subscription_percent_consumed_stats
    @subscription_percent_consumed_stats ||= 
      Statistic.find_for_org(self.key, 
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

end
