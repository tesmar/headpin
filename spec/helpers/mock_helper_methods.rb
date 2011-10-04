module MockHelperMethods

  def mock_org key=nil, displayName=nil
    key ||= random_string
    displayName ||= random_string
    # TODO: this is sufficient for an org as far as we're concerned, but an
    # actual org queried from Candlepin will have many other properties:
    mock(Organization, :key => key, :displayName => displayName)
  end

  def real_org
    #since admin has many....
    Organization.retrieve_by_user("admin")[0]
  end

  def real_system
    System.retrieve_all[-1]
  end

  def real_user
    #grab the last user for fun
    User.retrieve_all[-1]
  end

  def real_role
    Role.retrieve_all[-1]
  end

  def real_activation_key
    #since admin has many....
    org = Organization.retrieve_by_user("admin")[0]
    ActivationKey.retrieve_by_org(org.key)[0]
  end

  def random_string(prefix=nil)
    prefix ||= ''
    "#{prefix}#{rand(1000000000)}"
  end

end
