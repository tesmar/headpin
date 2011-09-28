class Tableless
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  TRUE_VALUES = [true, 1, "1", "true", "yes", "TRUE", "YES", "T", "t", "Y", "y"]
  attr_accessor :json_hash

  def initialize(json_hash=nil)
    @json_hash = (json_hash ||= {})
    #not everyone will have all of these fields but this is just to cover us in the general case
    if @json_hash != {}
      @cp_id = @json_hash["id"]
      @uuid = @json_hash["uuid"]
      @consumer_type = @json_hash["type"]
    end
    if Rails.env.development?
      Rails.logger.ap "Received new #{self.class.to_s}"
      Rails.logger.ap @json_hash
    end
    @json_hash
  end
  #default id, override if needed
  def id
    @json_hash["id"]
  end

  def update_attributes(attr ={})
    attr.each_pair do |key, value|
      @json_hash[key] = value
    end
  end

  #this is for activeModel to know this object is not persisted in the db
  def persisted?
    false
  end

  #this is for activeView, override if needed.
  def to_param
    id
  end

end #end class
