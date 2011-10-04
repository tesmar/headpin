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

    it "should flash a failure message" do
      ##controller.stub!(:errors).and_return true
      post 'create', post_to_headpin_create_data_bad_name
      ##controller.should_receive(:errors)
      #flash[:error][:summary].should =~ /System name cannot contain most special characters./
      response.should_not be_success
      response.body.should =~ /System name cannot contain most special characters./
    end
  end

  describe "POST update subscriptions" do
    #let(:sys) { real_system }
    it "should call bind" do
      # This will set the @system to an instance that can be
      # checked.
      sys = real_system
      controller.stub!(:find_system).and_return(true)
      controller.instance_variable_set(:@system, sys)
      org = Organization.retrieve(sys.owner_key)
      controller.instance_variable_set(:@organization, org)
      System.stub!(:bind).and_return(true)

      controller.instance_variable_get(:@system).should_receive(:bind).and_return(true)
      controller.should_receive(:notice).with("System subscriptions updated.")

      params = post_to_headpin_systems_update_subscriptions
      params[:id] = sys.uuid
      post 'update_subscriptions', params

      response.should render_template(:partial => "systems/_subs_update")
      #flash[:notice].should =~ /System subscriptions updated./
    end
  end

end

