require 'bundler'

Bundler.require(:default)
require 'sinatra/base'

%W{
  lib/rack_port_monkeypatch
  lib/omniauth/strategies/identity
  lib/omniauth/form
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

}.each{|lib|require File.expand_path('../../'+lib, __FILE__)}
