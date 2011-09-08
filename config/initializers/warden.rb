require 'net/https'
require 'json'

Rails.configuration.middleware.use RailsWarden::Manager do |manager|
  manager.default_strategies :candlepin
  manager.failure_app = LoginController
end

# Setup Session Serialization
class Warden::SessionSerializer
  def serialize(user)
    user 
  end

  def deserialize(user)
    user
  end
end

Warden::Strategies.add(:candlepin) do

  def valid?
    params[:username] && params[:password]
  end

  def authenticate!
    username = params[:username]

    begin
      http = Net::HTTP.new(AppConfig.candlepin.url, AppConfig.candlepin.port)
      req = Net::HTTP::Get.new("#{AppConfig.candlepin.prefix}/users/#{username}")
      http.use_ssl = true
      req.basic_auth username, params[:password]
      response = http.request(req)
    rescue
      return fail! _("Request failed. Check that Candlepin is properly configured and running.")
    end
    
    if response.code == '200'
      success! User.new(JSON.parse(response.body()))
    else
      fail! _("You've entered an incorrect username or password combination, please try again.")
    end

  end
end
