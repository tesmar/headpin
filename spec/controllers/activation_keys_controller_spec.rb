require 'spec_helper'

describe ActivationKeysController do
  include LoginHelperMethods
  include MockHelperMethods
  render_views

  before (:each) do
    login_user
  end

  describe "GET index" do
    it 'should be successful' do
      org = real_org
      get 'index', {}, {:current_organization_id => org.key}
      response.should be_success
    end
  end

  describe "GET new" do
    it 'should be successful' do
      org = real_org
      get 'new', {}, {:current_organization_id => org.key}
      response.should be_success
    end
  end

  describe "GET edit" do
    it 'should be successful' do
      activation_key = real_activation_key
      get 'edit', :id => activation_key.id
      response.should be_success
    end
  end

=begin
  Need clarification on how tests are run: Against live Candlepin or should there be a mock/stub layer?
  Also worth noting is that the 'create' doesn't work in the UI or here.

  describe "GET update" do
    it 'should be successful' do
      activation_key = real_activation_key
      get 'update', {:id => activation_key.id, :activation_key => {:name => "new_name"}}
      response.should be_success
    end
  end

  describe "POST create" do
    it 'should be successful' do
      org = real_org
      post 'create', {:name => "new_key", :current_organization_id => org.key}
      response.should be_success
    end
  end

  describe "DELETE destroy" do
    it 'should be successful' do
      activation_key = real_activation_key
      delete 'destroy', :id => activation_key.id
      response.should be_success
    end

    it 'should not be successful' do
      delete 'destroy', :id => "9999"
      response.should_not be_success
    end
  end
=end

end
