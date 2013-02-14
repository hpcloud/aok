source (ENV['RUBYGEMS_MIRROR'] or 'https://rubygems.org')

ruby '1.9.3' # prevents hard-to-diagnose errors with bundle install

gem 'sinatra', '~>1.3.3'

group :development do
  # Source reloading during development
  gem 'rerun'
  gem 'rb-inotify'
end

group :test do
  gem 'rspec'
  gem 'rack-test'
end

# OpenID support
gem 'ruby-openid', '~>2.2.2'

# cluster/config stuff
gem 'stackato-kato', :require => ['kato/doozer']
gem 'vcap_common', :require => ['vcap/common', 'vcap/component', 'vcap/util'], :path => '../vcap/common'
gem 'thin'

# ActiveRecord stuff
gem 'rake'
gem 'activerecord', '~>3.0.20', :require => 'active_record'
gem 'pg'
gem 'bcrypt-ruby', :require => 'bcrypt'

#Auth
gem 'omniauth', '~>1.1.1'
gem 'omniauth-identity', '~>1.1.0'
gem 'omniauth-ldap', '~>1.0.2'
