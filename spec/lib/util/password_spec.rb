require 'spec_helper'
describe Password do
  describe 'candlepin integration' do
    it 'should be validate the admin password' do
      result = Password.check("admin", "e3e80f61a902ceca245e22005dffb4219ac1c5f7")
      result.should == true
    end
    
    it 'should be not validate garbage' do
      result = Password.check("JarJarBinks", "NotAJedi")
      result.should == false
    end    

  end
end
