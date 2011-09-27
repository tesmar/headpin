class headpin {
  include candlepin
  include apache2
  include headpin::params
  include headpin::install
  include headpin::config
  include headpin::service
}
