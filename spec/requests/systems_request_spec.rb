require 'spec_helper'

describe "System Request Specs" do
  include LoginHelperMethods
  include MockHelperMethods
  include SystemControllerTestHelper


  before (:each) do
    post '/login', :username => "doc", :password => "password"
    u = User.new({"username" => "doc", "superAdmin" => true})
    User.current = u
  end

  context 'system CRUD' do

    it 'should send a zip file to the user of the certificates' do
      org = real_org
                       # Get index, simulate session setting for the current organization:
      s = System.new
      s.owner = mock(Object, :key => "admin")
      s.arch = "i386"
      s.sockets = "32"
      s.virtualized = 'virtual'
      s.name = "TestSys"
      new_s = s.create #create a system
      get("/systems/#{new_s.uuid}/manifest_dl")
      response.should be_success
      response.body.should_not be_nil
                       #delete the created system
      new_s.destroy
    end

    it "should successfully delete a system" do
      s = ready_to_be_created_system.create
      delete "/systems/#{s.uuid}"
      response.should redirect_to("/systems")
    end

    it "should flash a message upon successful deletion" do
      s = ready_to_be_created_system.create
      delete "/systems/#{s.uuid}"
      response.should be_redirect
      flash[:notice].should eq("Deleted system #{s.name}.")
    end
  end

  context 'system sub items' do
        
    before(:each) do
      @sys ||= ready_to_be_created_system.create
    end

    after(:all) do
      delete "/systems/#{@sys.uuid}"
    end

    it "should successfully get a system products" do
      get "/systems/#{@sys.uuid}/products"
      response.status.should eql(200)
    end

    it "should successfully get a system facts" do
      get "/systems/#{@sys.uuid}/facts"
      response.status.should eql(200)
    end

    it "should successfully get a system subscriptions" do
      get "/systems/#{@sys.uuid}/subscriptions"
      response.status.should eql(200)
    end

    it "should successfully get a system events" do
      get "/systems/#{@sys.uuid}/events"
      response.status.should eql(200)
    end
  end
end
