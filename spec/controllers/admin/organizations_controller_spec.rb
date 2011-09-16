require 'spec_helper'

describe Admin::OrganizationsController do
  include LoginHelperMethods
  include MockHelperMethods
  render_views

  before (:each) do
    login_user
  end

  describe "GET index" do
    context 'with no existing organizations' do
      it 'should be successful' do
        get 'index'
        response.should be_success
      end
    end

    context 'as non-admin' do
      it 'should redirect to dashboard' do
        org = real_org()
        mock_user = mock(User, :superAdmin? => false, :username => "admin")
        mock_user.stub_chain(:owner, :key).and_return(org.key)
        controller.stub!(:logged_in_user).and_return(mock_user)
        get 'index'
        response.should redirect_to dashboard_index_url
      end
    end

  end

  describe "GET new" do
    it 'should be successful' #do
    #  get 'new'
    #  response.should be_success
    #end
  end

  describe "POST create" do

    it 'should create a new organization' do
      org = real_org()
      org.should_receive(:save).and_return(true)
      Organization.stub!(:new).and_return org
      post 'create', :organization => {:key => '', :displayName => ''}
      response.should redirect_to admin_organizations_path
    end
  end

  describe "POST update" do
    it 'should update organization'
    #do
    #  org = real_org()
    #  Organization.stub!(:save!).and_return org
    #  post 'update', {:id => org.key, :organization => {:displayName => random_string("orgname")}}
    #  response.should be_success
    #end
  end

  describe "GET edit" do
    it 'should be successful' do
      org = real_org()
      get 'edit', :id => org.key
      response.should be_success
    end
  end

=begin
  TODO: This really doesn't work yet

  describe "GET events" do
    it 'should be successful' do
      org = real_org()
      get 'events', :id => org.key
      response.should be_success
    end
  end
=end

  describe "GET systems" do
    it 'should change the working org' do
      org = real_org()
      get 'systems', :id => org.key
      session[:current_organization_id].should == org.key
    end

    it 'should redirect to top-level systems path' do
      org = real_org()
      Organization.should_receive(:retrieve).with(org.key).and_return(org)
      get 'systems', :id => org.key
      response.should redirect_to(systems_path)
    end
  end

  describe "GET subscriptions" do
    it 'should change the working org' do
      org = real_org
      #Organization.should_receive(:find).with(org.key).and_return(org)
      #Organization.should_receive(:find).with(:all, anything()).and_return([org])
      get 'subscriptions', :id => org.key
      session[:current_organization_id].should == org.key
    end

    it 'should redirect to top-level systems path' do
      org = real_org()
      Organization.should_receive(:retrieve).with(org.key).and_return(org)
      get 'subscriptions', :id => org.key
      response.should redirect_to(subscriptions_path)
    end
  end
end

