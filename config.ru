require 'bundler/setup'
require 'sinatra/base'

require './helpers/application_helper'

require './controllers/application_controller'
require './controllers/openid_controller'
require './controllers/users_controller'

maps = {
  '/'        => ApplicationController,
  '/openid'  => OpenidController,
  '/users'   => UsersController
}
maps.each do |path, controller|
  map(path){ run controller}
end
