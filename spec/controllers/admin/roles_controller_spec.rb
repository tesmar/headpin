require 'spec_helper'

describe Admin::RolesController do
  include LoginHelperMethods
  include MockHelperMethods
  render_views

  before (:each) do
    login_user
  end

  describe "GET index" do
      it 'should be successful' do
        get 'index'
        response.should be_success
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
    it 'should be successful' do
      get 'new'
      response.should be_success
    end
  end

  describe "POST create" do

    it 'should create a new role' do
      post 'create', :role => {:name => random_string}
      response.should be_success
    end
  end

  context "updating a role" do
    describe "PUT update" do
      it 'should update a role' do
        role = Role.new({"name" => random_string}).save
        put 'update', {:id => role.cp_id, :role => {:name => random_string("rolename")}}
        response.should be_success
        #not to clutter the DB
        role.destroy
      end

      it 'should bind a user to a role' do
        role = Role.new({"name" => random_string}).save
        put 'update', {:id => role.cp_id, :update_users => {:user_id => real_user.username, :adding => "true"}}
        response.should be_success
        role_after_update = Role.retrieve(role.cp_id)
        role_after_update.users.size.should eq(1)
        #not to clutter the DB
        role_after_update.destroy
      end

      it 'should unbind a user from a role' do
        user = real_user
        role = Role.new({"name" => random_string}).save
        role.add_user(user)
        role_with_one_user = Role.retrieve(role.cp_id)
        role_with_one_user.users.size.should eq(1)
        put 'update', {:id => role.cp_id, :update_users => {:user_id => user.username, :adding => "false"}}
        response.should be_success
        role_after_update = Role.retrieve(role.cp_id)
        role_after_update.users.size.should eq(0)
        #not to clutter the DB
        role_after_update.destroy
      end
    end
  end

  describe "GET edit" do
    it 'should be successful' do
      role = real_role()
      get 'edit', :id => role.cp_id
      response.should be_success
    end
  end

  describe "permissions" do
    it 'should repond SUCCESS when we add a permission to a role' do
      role = real_role
      post 'create_permission', :role_id => role.cp_id, :permission => {:organization_id => real_org.key},
                                :perm_level => "READ_ONLY"
      response.should be_success
    end

    it 'should repond actually save a permission to a role' do
      role = real_role
      prev_size = role.permissions.size
      post 'create_permission', :role_id => role.cp_id, :permission => {:organization_id => real_org.key},
                                :perm_level => "READ_ONLY"
      response.should be_success
      role = Role.retrieve(role.cp_id)
      role.permissions.size.should eq(prev_size.to_i + 1)
    end

    it 'should respond SUCCESS when we remove a permission from a role' do
      role = real_role
      role.save_permission("ALL",real_org.key)
      delete 'destroy_permission', :role_id => role.cp_id, :permission_id => role.permissions[0]["id"]
      response.should be_success
    end

    it 'should actually remove a permission from a role' do
      role = real_role
      role.save_permission("ALL",real_org.key)
      role = Role.retrieve(role.cp_id)
      prev_size = role.permissions.size
      delete 'destroy_permission', :role_id => role.cp_id, :permission_id => role.permissions[0]["id"]
      response.should be_success
      role = Role.retrieve(role.cp_id)
      role.permissions.size.should eq(prev_size -1)
    end
  end

end

