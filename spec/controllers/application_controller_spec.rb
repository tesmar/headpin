 require 'spec_helper'

describe ApplicationController do
  include LoginHelperMethods
  include MockHelperMethods

  before (:each) do
    login_user
  end

  describe "set_org" do
    it 'should set the current organization in the session' do
      org = real_org()
      Organization.should_receive(:retrieve).with(org.key).and_return(org)
      request.env['HTTP_REFERER'] = "/"
      post :set_org, :workingorg => org.key
      session[:current_organization_id].should == org.key
    end
  end
end
 
