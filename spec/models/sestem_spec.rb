require 'spec_helper'

describe System do
  describe 'new System' do
    #attr_accessor :name, :entitlementCount, :uuid, :owner_key
    #attr_accessor :created, :lastCheckin, :username, :facts, :owner
    #attr_accessor :arch, :sockets, :virtualized, :products

    it 'new system should be valid' do
      System.new.should be_valid
    end

    it 'system should have setters accessor' do
      s= System.new
      s.owner = mock(Object, :key => "admin")
      s.arch = "i386"
      s.sockets = "32"
      s.virtualized = 'virtual'
      s.name = "ASys"
    end

    it 'system should have getters accessor' do
      s= System.new
      s.owner.should eq(nil)
      s.arch.should eq(nil)
      s.sockets.should eq(nil)
      s.virtualized.should eq(nil)
      s.name.should eq(nil)
      s.products.should eq(nil)
      s.facts.should eq(nil)
    end

  end
end
