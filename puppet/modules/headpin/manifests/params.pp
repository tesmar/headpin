class headpin::params {
    
  # system settings
  $user        = "headpin"
  $group       = "headpin"
  $config_dir  = "/etc/headpin"
  $headpin_dir = "/usr/share/headpin"
  $environment = "production"

  # SSL settings
  $ssl_certificate_file     = "/etc/candlepin/certs/candlepin-ca.crt"
  $ssl_certificate_key_file = "/etc/candlepin/certs/candlepin-ca.key"
  $ssl_certificate_ca_file  = $ssl_certificate_file

  # apache settings
  $thin_start_port = "5000"
  $thin_log        = "/var/log/headpin/thin-log.log"

  # OAUTH settings
  $oauth_key    = "headpin"
  $oauth_secret = "hdsj824hjsa9k3h28dk559sh" # TODO: Make this dynamic one time

  # Subsystems settings
  $candlepin_url = "https://localhost:8443/candlepin"
}
