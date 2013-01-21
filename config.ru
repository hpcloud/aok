Dir.chdir(File.dirname(__FILE__))
require 'bundler'
Bundler.require(:default)
require 'sinatra/base'

%W{
  lib/omniauth_identity_patch

  config/config

  helpers/application_helper
  helpers/current_user_helper

  controllers/application_controller
  controllers/openid_controller
  controllers/users_controller
  controllers/logins_controller

  models/identity

}.each{|lib|require File.expand_path('../'+lib, __FILE__)}

maps = {
  '/'        => ApplicationController,
  '/openid'  => OpenidController,
  '/users'   => UsersController,
  '/logins'  => LoginsController
}
maps.each do |path, controller|
  map(path){ run controller}
end


