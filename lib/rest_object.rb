module RestObject
  include HTTParty
  debug_output $stderror

  #format :json

  attr_accessor :cp_id, :consumer_type

  def initialize(json_hash=nil)
    @json_hash = json_hash
    @json_hash ||= {}
    # rails doesn't like variables called id or type
    if @json_hash != {} 
      @cp_id = @json_hash["id"]
      @consumer_type = @json_hash["type"]
    end
  end

  def method_missing(m, *args, &block)
    if @json_hash
      @json_hash[m.to_s] unless assignment(m.to_s, *args)
    else
      nil
    end
  end

  def assignment(m, *args)
    # don't allow an assignment operator, instead execute it
    if m =~ /=$/
      @json_hash[m.to_s.split("=")[0].chomp] = args.first
      return true
    end
    return false
  end

  def formatDate(date_str, format_str)
    date = Date.parse(date_str)
    return date.strftime(format_str)
  end

  def formattedEndDate
    return Date.parse(@json_hash["endDate"])
  end

  def formattedStartDate
    return Date.parse(@json_hash["startDate"])
  end

  def typelabel
    return @consumer_type["label"]
  end


  #CLASS METHODS
  module ClassMethods

    def auth_header(username, locale)
      return { :headers => { "cp-user" => username, "Accept-Language" => locale } }
    end

    def check_response(response)
      case response.code
      when 200..299
        return response 
      when 400
        raise ArgumentError, response.parsed_response["displayMessage"]
      when 401
        raise SecurityError, response.parsed_response["displayMessage"]
      when 403
        raise SecurityError, response.parsed_response["displayMessage"]
      when 404
        raise ArgumentError, response.parsed_response["displayMessage"]
      else
        raise Exception, "[" + response.code.to_s + "] [" + response.message + "]"
      end
    end

    # override default httparty methods to call our exception handler
    def checked_post(url, options={})
      return check_response(post(url, options))
    end

    def checked_get(url, options={})
      return check_response(get(url, options))
    end

    def checked_put(url, options={})
      return check_response(put(url, options))
    end

    def checked_delete(url, options={})
      return check_response(delete(url, options))
    end
  end #ends ClassMethodsModule
  #END CLASS METHODS

  def self.included(base)
    base.extend(ClassMethods)
  end
  class NotReadyError < StandardError; end
end
