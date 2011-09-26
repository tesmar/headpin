class headpin::config {

  config_file {
    "${headpin::params::config_dir}/thin.yml":
      template => "headpin/${headpin::params::config_dir}/thin.yml.erb";
    "${headpin::params::config_dir}/headpin.yml":
      template => "headpin/${headpin::params::config_dir}/headpin.yml.erb";
    "/etc/httpd/conf.d/headpin.conf":
      template => "headpin/etc/httpd/conf.d/headpin.conf.erb",
      notify   => Exec["reload-apache2"];
  }
  file{"/var/log/headpin":
    owner   => $headpin::params::user,
    group   => $headpin::params::group,
    mode    => 644,
    require => Class["headpin::install"],
    recurse => true;
  }

  define config_file($source = "", $template = "") {
    file {$name:
      content => $template ? {
        "" => undef,
          default =>  template($template)
      },
      source => $source ? {
        "" => undef,
        default => $source,
      },
      require => Class["headpin::install"];
    }
  }
}
