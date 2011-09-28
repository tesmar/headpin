require 'spec_helper'
describe User do
  describe 'new User validation' do
    it 'should be valid after creation' do
      User.new.should be_valid
    end

    it 'should be able to be made superAdmin' do
      u = User.new({"superAdmin" => true})
      u.should be_valid
      u.superAdmin.should eql(true)
    end

    it 'should authenticate with admin' do
      u = User.authenticate!("admin", "admin")
      puts u.password
      u.should_not be nil
    end
  end
end
