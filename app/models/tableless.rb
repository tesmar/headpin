class Tableless
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
    @json_hash
  end

end #end class
