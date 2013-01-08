require 'bundler'
Bundler.require(:default)
require 'sinatra/base'

require './config/database'

require './helpers/application_helper'
require './helpers/current_user_helper'

require './controllers/application_controller'
require './controllers/openid_controller'
require './controllers/users_controller'

require './models/user'
