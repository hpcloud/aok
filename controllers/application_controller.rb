require 'logger'
class ApplicationController < Sinatra::Base
  helpers ApplicationHelper, CurrentUserHelper, ErrorHandlingHelper

  set :raise_errors, true
  set :show_exceptions, false

  # IP Spoofing protection isn't that helpful and
  # causes a lot of warnings in the log
  set :protection, :except => :ip_spoofing

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
    # The normal Sinatra logger
    set :logging, Logger::DEBUG

    # This is another logger for use in the Application scope
    logger = Logger.new $stdout
    logger.level = Logger::DEBUG
    logger.datetime_format = '%a %d-%m-%Y %H%M '
    set :logger, logger
    $stdout.sync = true
  end

  helpers do
    def logger
      settings.logger
    end
  end

  # OAuth2 Resource Server
  require 'rack/oauth2'
  require 'rack/oauth2/server/token/extension/jwt'
  use Rack::OAuth2::Server::Resource::Bearer, 'AOK Protected Resources' do |req|
    AccessToken.valid.find_by_token(req.access_token) || req.invalid_token!
  end


  # Register with the router
  require 'nats/client'
  def self.nats_message(subject, message, logger)
    NATS.start(:uri => CCConfig[:message_bus_uri], :max_reconnect_attempts => 999999) do
      NATS.publish(subject, message) do
        logger.debug "NATS server received message."
        NATS.stop
      end
    end
  end
  configure do
    Aok::Config::Strategy.initialize_strategy
    Aok::Config.initialize_database
    set :public_folder, File.expand_path('../../public', __FILE__)
    logger.debug "Serving static files from #{settings.public_folder.inspect}"

    router_config = {
      :host => CCConfig[:bind_address],
      :port => AppConfig[:port],
      :uris => [CCConfig[:external_domain].sub(/^api/, 'aok')],
      :tags => { :component => "aok" }
    }.to_json
    logger.debug "Publishing router config: #{router_config}"
    nats_message('router.register', router_config, logger)

    # TODO: This doesn't seem to work.
    at_exit do
      logger.debug "Unregistering from router..."
      nats_message('router.unregister', router_config, logger)
    end
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
    user = env['omniauth.identity']
    set_current_user(user)

    if env["aok.block"] # legacy login
      env["aok.block"].call(user)
      return
    end

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
    logger.debug "="*80
    logger.debug "ENV:\n\t" + en.collect.sort{|a,b|a.first.downcase<=>b.first.downcase}.collect{|k,v|"#{k.inspect} => #{v.inspect}"}.join("\n\t")
    logger.debug "="*80
  end

  helpers do
    def direct_login(username, password, &block)
      # Take the credentials that were posted to us and simulate a form
      # submission on the configured omniauth strategy. We're basically
      # rewinding the Rack call stack, mapping the credentials we were
      # given in to what OmniAuth is expecting for this strategy, and
      # then replaying Rack starting at the OmniAuth callback.

      # Put together our request body that looks like a form submission
      id_field = Aok::Config::Strategy.id_field_for_strategy
      secret_field = Aok::Config::Strategy.secret_field_for_strategy
      form_hash = {id_field => username, secret_field => password}
      form_string = URI.encode_www_form(form_hash)
      form_io = StringIO.new(form_string)

      # Find what strategy we're using
      strategy = settings.strategy.to_s
      klass = OmniAuth::Strategies.const_get("#{OmniAuth::Utils.camelize(strategy)}")
      middleware = ApplicationController.middleware.find{|m| m.first == klass}
      middleware_options = middleware[1].first

      # Fake out Rack to think we're on the auth callback with our synthesized form body
      path = "/auth/#{strategy}/callback"

      session # need this to ensure env['rack.session'] is set, needed by omniauth

      env.merge!(
        "REQUEST_METHOD"=>"POST",
        "REQUEST_PATH" => path,
        "PATH_INFO" => path,
        "REQUEST_URI" => path,
        "rack.input" => form_io,
        "CONTENT_TYPE" => "application/x-www-form-urlencoded",
        "aok.no_openid" => true, # just return a status code, no openid redirects
        "aok.block" => block # call the block (if provided) with the login result
      )

      # Call the middleware, which will then call up in to the auth code
      # in ApplicationController. The results can be returned directly.
      klass.new(self, middleware_options).call!(env)
    end
  end

end
