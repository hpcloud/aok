require 'time'
require 'uaa'
class UaaController < ApplicationController

  # OAuth2 Token Validation Service
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#oauth2-token-validation-service-post-check_token
  post '/check_token' do
    raise Aok::Errors::NotImplemented
  end

  # OpenID Check ID Endpoint
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#openid-check-id-endpoint-post-check_id
  post '/check_id' do
    raise Aok::Errors::NotImplemented
  end

  # OpenID User Info Endpoint
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#openid-user-info-endpoint-get-userinfo
  get '/userinfo' do
    raise Aok::Errors::NotImplemented
  end

  # Login Information API
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#login-information-api-get-login
  # TODO: return real information determined from the current configured strategy
  get '/login', :provides => :json do
    return {
      :timestamp => Time.now.xmlschema,
      :commit_id => AppConfig[:commit_id],
      :prompts => {
        :username => ["text","Username"],
        :password => ["password","Password"]
      }
    }.to_json
  end

  # Converting UserIds to Names
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#converting-userids-to-names
  # Note: This will probably not be implemented in AOK
  get '/ids/Users' do
    raise Aok::Errors::NotImplemented
  end

  # Query the strength of a password
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#query-the-strength-of-a-password-post-passwordscore
  post '/password/score' do
    raise Aok::Errors::NotImplemented
  end

  # UAA has overloaded this endpoint
  #
  # Internal Login Form
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#internal-login-form-get-login
  #
  # External Hosted Login Form (OpenID)
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#external-hosted-login-form-openid-get-login
  get '/login', :provides => :html do
    raise Aok::Errors::NotImplemented
  end

  # Internal Login
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#internal-login-post-logindo
  post '/login.do', :provides => :html do
    raise Aok::Errors::NotImplemented
  end

  # Logout
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#logout-get-logoutdo
  get '/logout.do', :provides => :html do
    raise Aok::Errors::NotImplemented
  end

  # Get the Token Signing Key
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#get-the-token-signing-key-get-token_key
  get '/token_key' do
    raise Aok::Errors::NotImplemented
  end

  # Basic Metrics
  # Note: This endpoint appears to be broken in UAA
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#basic-metrics-get-varz
  get '/varz' do
    raise Aok::Errors::NotImplemented
  end

  # Detailed Metrics
  # Note: This endpoint appears to be broken in UAA
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#detailed-metrics-get-varzdomain
  get '/varz/:domain' do
    raise Aok::Errors::NotImplemented
  end

  # Simple Health Check
  # Undocumented in UAA
  get '/healthz', :provides => 'text/plain' do
    "ok\n"
  end


end