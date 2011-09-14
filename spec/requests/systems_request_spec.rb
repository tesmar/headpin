require 'spec_helper'

describe "System Request Specs" do
  include LoginHelperMethods
  include MockHelperMethods


  before (:each) do
    post '/login', :username => "doc", :password => "password"
    u = User.new({"username" => "doc", "superAdmin" => true})
    User.current = u
  end

  it 'should send a zip file to the user of the certificates' do
    org = real_org
    # Get index, simulate session setting for the current organization:
    s = System.new
    s.owner_key = "admin"
    s.create #create a system
    system = System.retrieve_all[0]
    get("/systems/#{system.uuid}/manifest_dl")
    response.should be_success
    response.body.should_not be_nil
  end
end
