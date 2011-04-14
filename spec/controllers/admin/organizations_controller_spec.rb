require 'spec_helper'

describe Admin::OrganizationsController do

  include LoginHelperMethods
  include MockHelperMethods

  before (:each) do
    login_user
  end

  describe "GET index" do

    context 'with no existing organizations' do

      it 'should be successful' do
        Organization.should_receive(:find).with(:all).and_return([])
        get 'index'
        response.should be_success
      end

    end

    context 'as non-admin' do
      it 'should redirect to dashboard' do
        mock_user = mock(User, :superAdmin? => false)
        controller.stub!(:logged_in_user).and_return(mock_user)
        get 'index'
        response.should redirect_to '/dashboard'
      end
    end

  end

  describe "use" do
    it 'should set the current organization in the session' do
      org = mock_org()
      Organization.should_receive(:find).with(org.key).and_return(org)
      get :use, :id => org.key
      session[:current_organization_id].should == org.key
    end
  end

  describe "GET new" do
    it 'should be successful' do
      get 'new'
      response.should be_success
    end
  end

  describe "POST create" do

    it 'should create a new organization' do
      org = mock_org()
      org.should_receive(:save).and_return(true)
      Organization.stub!(:new).and_return org

      post 'create', :organization => {:key => '', :displayName => ''}
      response.should redirect_to("http://test.host/admin/organizations/#{org.key}")
    end
  end

end
