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
      u = User.authenticate!(params[:username], params[:password])
    rescue
      return fail! _("Request failed. Check that Candlepin is properly configured and running.")
    end

    u ? success!(u) : fail!(_("Username or password is not correct - could not log in"))
  end
end
