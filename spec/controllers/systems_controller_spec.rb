require 'spec_helper'


describe SystemsController do
  include LoginHelperMethods
  include MockHelperMethods
  include SystemControllerTestHelper
  render_views

  before (:each) do
    login_user
  end

  describe "GET index" do
    it 'should be successful' do
      org = real_org
      # Get index, simulate session setting for the current organization:
      get 'index', {}, {:current_organization_id => org.key}
      response.should be_success
    end

    context 'with no working org selected' do
      it 'should redirect to org selection' do
        org = real_org
        #Organization.should_receive(:find).with(:all, anything()).and_return([org])
        # Get index, no current org in the session:
        controller.working_org.should be_nil
        get 'index'
        controller.working_org.key.should == org.key
        response.should be_success
      end
    end
  end

  describe "POST create" do
    it "should not redirect to another page after successful creation" do
      post 'create', post_to_headpin_create_data
      response.should_not be_redirect
    end

    it "should flash a successful creation message upon creation" do
      #new_s = ready_to_be_created_system.create
      post 'create', post_to_headpin_create_data
      flash[:notice].should =~ /System .* was created./
    end

   # it "should redirect to the dashboard and flash a warning upon a candlepin error" do
#      s = ready_to_be_created_system
#System.stub!(:new).and_return(s)
#      s.should_receive(:create).and_raise(Exception)
#      post 'create', post_to_headpin_create_data
#      response.should redirect_to '/dashboard'

    #end
  end

end

