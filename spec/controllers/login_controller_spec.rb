require 'spec_helper'

describe LoginController do

  describe '#index' do
    it 'should redirect to the login page' do
      get 'index'
      response.should redirect_to(:action => :new)
    end
  end

  describe '#create' do

    before(:each) do
      controller.stub! :require_no_user
    end

    it 'should redirect invalid username/password' do
      # This is what warden will do internally
      controller.stub!(:authenticate!) { controller.unauthenticated }
      controller.stub!(:logged_in?).and_return false

      post 'create'

      response.should redirect_to(:action => :new)
    end

    it 'should redirect back to the original uri on successful login' do
      controller.stub! :authenticate! 
      controller.stub!(:logged_in?).and_return true
      controller.session[:original_uri] = '/systems'

      post 'create'

      response.should redirect_to('/systems')
    end

    it 'should redirect to the dashboard if no original uri is set' do
      controller.stub! :authenticate! 
      controller.stub!(:logged_in?).and_return true
     
      post 'create'

      response.should redirect_to(:controller => :dashboard, :action => :index)
    end
  end

  describe '#destroy' do
    
    before(:each) do
      controller.stub! :require_user
    end

    it 'should display a logout message' do
      controller.stub! :logout
      delete 'destroy'

      flash[:notice].should include('Successful')
    end

    it 'should redirect back to the login screen on logout' do
      controller.stub! :logout
      delete 'destroy'

      response.should redirect_to(:action => :new)
    end
  end
end