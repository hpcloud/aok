Dir.chdir(File.dirname(__FILE__))
require 'bundler'
Bundler.require(:default)
require 'sinatra/base'

%W{
  lib/omniauth_identity_patch
  lib/active_record_session_store

  config/config

  helpers/application_helper
  helpers/current_user_helper

  controllers/application_controller
  controllers/openid_controller
  controllers/users_controller
  controllers/logins_controller

  models/identity
  models/session

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


