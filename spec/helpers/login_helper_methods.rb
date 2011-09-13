module LoginHelperMethods

  # Mock a logged in warden user:
  def login_user(user=nil)
    @username = user || "admin"
    user_obj = stub(User, :username => @username, :superAdmin? => true, :page_size => 20, :cp_oauth_header => { 'cp-user' => 'admin' })
    stub_user = stub(Warden, :user => user_obj, :authenticate => @username, :authenticate! => @username)
    request.env['warden'] = stub_user
    Thread.current[:request] = request
    User.current = user_obj
  end

end
