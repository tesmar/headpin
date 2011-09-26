class headpin::service {
  service {"headpin":
    ensure  => running, enable => true, hasstatus => true, hasrestart => true,
    require => [Class["headpin::config"],Class["candlepin::service"], Class["apache2::config"]],
    notify  => Exec["reload-apache2"];
  }

}
