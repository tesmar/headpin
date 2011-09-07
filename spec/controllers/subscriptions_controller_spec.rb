require 'spec_helper'

describe SubscriptionsController do
  include LoginHelperMethods
  include MockHelperMethods

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


end
