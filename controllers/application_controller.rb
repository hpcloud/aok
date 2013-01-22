require 'logger'
class ApplicationController < Sinatra::Base
  helpers ApplicationHelper, CurrentUserHelper
  set :views, File.expand_path('../../views', __FILE__)
  set :logging, Logger::INFO

  # XXX: get secret from doozer
  use Rack::Session::Cookie, :secret => SecureRandom.urlsafe_base64(128)

  configure :development do
    set :logging, Logger::DEBUG
    puts "SETTING UP DEVELOPMENT ENVIRONMENT"
  end

  configure do
    Aok::Config.initialize_strategy
    Aok::Config.initialize_database
  end

  before do
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
    redirect '/openid/complete'
  end

  get '/auth/failure' do
    clear_current_user
    redirect '/openid/complete'
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

  def log_request_env
    logger.debug "REQUEST ENV:\n\t" + request.env.collect.sort{|a,b|a.first<=>b.first}.collect{|k,v|"#{k.inspect} => #{v.inspect}"}.join("\n\t")
  end

end
