require 'bundler'
Bundler.require(:default)

%W{
  lib/aok/errors
  lib/aok/security_context
  lib/aok/model_authorities_methods
  lib/aok/scim/active_record_query_builder
  lib/rack_port_monkeypatch
  lib/omniauth/strategies/identity
  lib/omniauth/form
  lib/active_record_session_store
  lib/active_record_openid_store/lib/openid_ar_store
  lib/database_reconnect
  lib/secure_token
  lib/oauth2_token

  config/config

  helpers/application_helper
  helpers/current_user_helper
  helpers/error_handling_helper

  controllers/application_controller
  controllers/login_endpoint
  controllers/root_controller
  controllers/oauth_controller
  controllers/openid_controller
  controllers/users_controller
  controllers/user_tokens_controller
  controllers/groups_controller
  controllers/clients_controller
  controllers/logins_controller

  models/identity
  models/session
  models/client
  models/access_token

}.each{|lib|require File.expand_path('../../'+lib, __FILE__)}

require_relative 'ensure_clients'
