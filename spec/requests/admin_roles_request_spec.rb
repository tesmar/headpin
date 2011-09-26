require 'spec_helper'

describe "Role Request Specs" do
  include LoginHelperMethods
  include MockHelperMethods


  before (:each) do
    post '/login', :username => "doc", :password => "password"
    u = User.new({"username" => "doc", "superAdmin" => true})
    User.current = u
  end

  it 'should properly delete a role' do
    user = real_user
    role = Role.new({"name" => random_string}).save
    delete "/admin/roles/#{role.cp_id}", :format => :js
    response.should be_success
    #deleted_role = Role.retrieve(role.cp_id)
 _  response.should be_success
    #flash[:notice].should eq("Role '#{role.name}' was deleted.")
  end
end
