require 'time'
require 'uaa'
class RootController < ApplicationController
  # TODO: Move to config
  MIMIMUM_PASSWORD_SCORE = 0

  get '/?' do
    redirect to('/uaa/')
  end

  get '/uaa/?', :provides => :html do
    require_user
    erb 'logged_in.html'.intern
  end

  get '/auth/?' do
    redirect "/auth/#{settings.strategy}"
  end

  # OAuth2 Token Validation Service
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#oauth2-token-validation-service-post-check_token
  post '/uaa/check_token/?' do
    authenticate!(:basic)
    CF::UAA::TokenCoder.decode(
      params[:token],
      {
        :skey => AppConfig[:jwt][:token][:signing_key]
      }
    ).to_json
  end

  # OpenID Check ID Endpoint
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#openid-check-id-endpoint-post-check_id
  post '/uaa/check_id/?' do
    raise Aok::Errors::NotImplemented
  end

  # OpenID User Info Endpoint
  # Really not sure what the point of this is
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#openid-user-info-endpoint-get-userinfo
  get '/uaa/userinfo/?', :provides => :json do
    authenticate!
    i = security_context.identity
    return {
      :user_id => i.username,
      :email => i.email
    }.to_json
  end

  # UAA has overloaded this endpoint
  #
  # Internal Login Form
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#internal-login-form-get-login
  #
  # External Hosted Login Form (OpenID)
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#external-hosted-login-form-openid-get-login
  get '/uaa/login/?', :provides => :html do
    require_user
  end

  # Undocumented API used in the UAA integration tests
  put '/uaa/approvals', :provides => :json do
    authenticate!
    log_env
    logger.debug "Approvals body: #{read_json_body}"
    raise Aok::Errors::NotImplemented
  end

  # Login Information API
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#login-information-api-get-login
  # TODO: return real information determined from the current configured strategy
  get '/uaa/login/?', :provides => :json do
    return {
      :timestamp => AppConfig[:timestamp].xmlschema,
      :commit_id => AppConfig[:commit_id],
      :prompts => {
        :username => ["text","Username"],
        :password => ["password","Password"]
      }
    }.to_json
  end

  # Undocumented API used in the UAA unit tests
  get '/uaa/info/?', :provides => :json do
    return {
       # "app" => {
       #    "version" => "1.4.3",
       #    "name" => "UAA",
       #    "artifact" => "cloudfoundry-identity-uaa",
       #    "description" => "User Account and Authentication Service"
       # },
       "timestamp" => AppConfig[:timestamp].xmlschema,
       "prompts" => [
          {
             "text" => "Username",
             "name" => "username",
             "type" => "text"
          },
          {
             "text" => "Password",
             "name" => "password",
             "type" => "password"
          }
       ],
       "commit_id" => AppConfig[:commit_id]
    }.to_json
  end

  # Converting UserIds to Names
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#converting-userids-to-names
  # Note: This will probably not be implemented in AOK
  get '/uaa/ids/Users/?' do
    raise Aok::Errors::NotImplemented
  end

  # Query the strength of a password
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#query-the-strength-of-a-password-post-passwordscore
  post '/uaa/password/score/?' do
    userdata = params[:userData] ? params[:userData].split(',') : []
    score = Zxcvbn.test(params[:password], userdata).score
    return {
      :score => score,
      :requiredScore => MIMIMUM_PASSWORD_SCORE
    }.to_json
  end

  # Internal Login
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#internal-login-post-logindo
  include LoginEndpoint

  # Logout
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#logout-get-logoutdo
  get '/uaa/logout.do', :provides => :html do
    raise Aok::Errors::NotImplemented
  end

  # Get the Token Signing Key
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#get-the-token-signing-key-get-token_key
  # It seems like insanity to have this endpoint with any symmetric-key signature
  get '/uaa/token_key/?' do
    raise Aok::Errors::NotImplemented
  end

  # Basic Metrics
  # Note: This endpoint appears to be broken in UAA
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#basic-metrics-get-varz
  get '/uaa/varz/?' do
    raise Aok::Errors::NotImplemented
  end

  # Detailed Metrics
  # Note: This endpoint appears to be broken in UAA
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#detailed-metrics-get-varzdomain
  get '/uaa/varz/:domain' do
    raise Aok::Errors::NotImplemented
  end

  # Simple Health Check
  # Undocumented in UAA
  get '/uaa/healthz/?', :provides => 'text/plain' do
    "ok\n"
  end


end
