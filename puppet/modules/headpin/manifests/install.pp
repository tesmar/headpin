class headpin::install {
  $os_type = $operatingsystem ? {
    "Fedora" => "fedora-${operatingsystemrelease}",
    default  => "\$releasever"
  }

  yumrepo { "fedora-headpin":
    descr    => 'front end for the candlepin engine',
    baseurl  => "http://repos.fedorapeople.org/repos/candlepin/headpin/$os_type/\$basearch/",
    enabled  => "1",
    gpgcheck => "0"
  }
  
  yumrepo { "fedora-katello":
    descr    => 'integrates together a series of open source systems management tools',
    baseurl  => "http://repos.fedorapeople.org/repos/katello/katello/$os_type/\$basearch/",
    enabled  => "1",
    gpgcheck => "0"
  }
    
  yumrepo { "fedora-headpin-source":
    descr    => 'front end for the candlepin engine',
    baseurl  => "http://repos.fedorapeople.org/repos/katello/katello/$os_type/SRPMS",
    enabled  => "0",
    gpgcheck => "0"
  }

	package{"headpin":
    require => [Yumrepo["fedora-headpin"],Yumrepo["fedora-katello"],Class["candlepin::install"]],
    before  => [Class["candlepin::config"] ], #avoid some funny post rpm scripts
    ensure  => installed
  }
}
