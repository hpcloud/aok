ENV['RACK_ENV'] = 'test'

# these value will override settings in the real config
$test_config = {
  :strategy => {
    :use => 'developer'
  }
}


require 'rspec'
require 'rack/test'

require_relative '../config/boot'


# setup test environment
set :environment, :test
set :run, false
set :raise_errors, false
set :show_exceptions, true

# def app
#   Sinatra::Application
# end

RSpec.configure do |config|
  config.include Rack::Test::Methods
end
