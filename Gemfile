source 'http://repos.fedorapeople.org/repos/katello/gems/'
source "http://rubygems.org"

gem 'rails', '3.0.5'
gem 'thin', '>=1.2.11'

gem 'rcov'
gem 'awesome_print'
gem 'json'
#gem 'bson_ext', '>= 1.0.4'
gem 'rails_warden'
gem 'rest-client', :require => 'rest_client'
gem 'oauth-active-resource'
# Dependency of oauth gem - but it lists the wrong one!
gem 'multipart-post'
# Stuff for view/display/frontend
gem 'haml', '>= 3.1.2'
gem 'haml-rails'
gem 'jammit'
gem 'compass', '>= 0.11.5'
gem 'compass-960-plugin', '>= 0.10.4'
gem 'simple-navigation', '3.3.4'
gem 'scoped_search', '>= 2.3.3'
# Stuff for i18n
gem 'gettext_i18n_rails'
gem 'i18n_data', '>= 0.2.6', :require => 'i18n_data'
# for gettext rake tasks
gem 'gettext', '>= 1.9.3', :require => false
gem 'ruby_parser', :require => false


# To use debugger (ruby-debug for Ruby 1.8.7+, ruby-debug19 for Ruby 1.9.2+)
 gem 'ruby-debug'
# gem 'ruby-debug19'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
  #gem 'webrat'
  gem 'rspec-rails'

  gem 'ruby-debug-base'
  gem 'ruby-debug-ide'
end

