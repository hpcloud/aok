require 'logger'
class ApplicationController < Sinatra::Base
  helpers ApplicationHelper, CurrentUserHelper
  set :logging, Logger::DEBUG

  # The session is only used for the duration of the login process
  # the expiration is set to 2 hours to allow for clock skew
  # between clients and the server.
  use Rack::Session::ActiveRecord, {
    :sidbits => 1024, 
    :expire_after => 2 * 60 * 60, #2 hours
    :httponly => true
  }

  configure :development do
    set :logging, Logger::DEBUG
    puts "SETTING UP DEVELOPMENT ENVIRONMENT"
  end

  configure do
    Aok::Config::Strategy.initialize_strategy
    Aok::Config.initialize_database
    set :public_folder, File.expand_path('../../public', __FILE__)
    puts "Serving static files from #{settings.public_folder.inspect}"
  end

  before '*' do
    headers({
      'X-XRDS-Location' => url("/openid/idp_xrds", true, false)
    })
  end

  def self.get_and_post(*args, &block)
    get(*args, &block)
    post(*args, &block)
  end

  get '/auth' do
    redirect "/auth/#{settings.strategy}"
  end

  post '/auth/:provider/callback' do
    email = auth_hash[:info][:email]
    user = Identity.new(:email => email)
    set_current_user(user)

    if env["aok.no_openid"] # legacy login
      return 200, {'Content-Type' => 'application/json'}, {:email => email}.to_json
    end

    redirect '/openid/complete'
  end

  get '/auth/failure' do
    # legacy login failures handles by Aok::Config::Strategy::FailureEndpoint
    clear_current_user
    redirect '/openid/complete'
  end

  get '/?' do
    redirect("https://#{CCConfig[:external_uri]}")
  end

  protected

  def auth_hash
    request.env['omniauth.auth']
  end

  def require_local
    host = request.host
    port = request.env['HTTP_X_SERVER_PORT']
    unless host == '127.0.0.1' && port == '9099'
      logger.debug "Unauthorized access attempted to #{host.inspect} port #{port.inspect}"
      halt 403
    end
  end

  def log_env(en=nil)
    en ||= env
    logger.error "="*80
    logger.error "ENV:\n\t" + en.collect.sort{|a,b|a.first.downcase<=>b.first.downcase}.collect{|k,v|"#{k.inspect} => #{v.inspect}"}.join("\n\t")
    logger.error "="*80
  end

end
