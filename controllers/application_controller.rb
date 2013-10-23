require 'logger'
require 'kato/local/node'

class ApplicationController < Sinatra::Base
  helpers ApplicationHelper, CurrentUserHelper, ErrorHandlingHelper

  set :raise_errors, true
  set :show_exceptions, false

  # IP Spoofing protection isn't that helpful and
  # causes a lot of warnings in the log
  set :protection, :except => :ip_spoofing

  set :logging, Logger::DEBUG

  set :views, File.absolute_path(File.dirname(__FILE__) + '/../views')

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
    ActiveRecord::Base.logger = logger
  end

  # OAuth2 Resource Server
  require 'rack/oauth2'
  require 'rack/oauth2/server/token/extension/jwt'
  use Rack::OAuth2::Server::Resource::Bearer, 'AOK Protected Resources' do |req|
    req.access_token # populates the environment used in SecurityContext
  end

  attr_reader :security_context
  before do
    content_type 'application/json'
    @security_context = Aok::SecurityContext.new(request)
  end

  get '/auth/failure' do
    # legacy login failures handles by Aok::Config::Strategy::FailureEndpoint
    clear_current_user
    redirect to('/openid/complete')
  end

  helpers do
    # authenticate(type=:oauth2)
    def authenticate!(*args)
      type = :oauth2
      if !args.blank?
        if [Symbol, String].include?(args.first.class)
          type_string = args.shift.to_s.downcase
          type = if type_string == 'basic'
            :basic
          elsif type_string =~ /^oauth2/
            # TODO: flesh this out to differentiate user/client auth
            :oauth2
          else
            nil
          end
        end
      end
      case type
      when :basic
        return if security_context.authenticated? && security_context.authentication.basic?
        if security_context.authenticated?
          logger.debug "Authentication was found, but not the expected type."
        end
        raise Aok::Errors::Unauthorized.new(
          "An Authentication object was not found in the SecurityContext", 'Basic', 'UAA/client'
        )
      when :oauth2
        return if security_context.authenticated? && security_context.authentication.oauth2?
        if security_context.authenticated?
          logger.debug "Authentication was found, but not the expected type."
        end
        raise Aok::Errors::Unauthorized.new(
          "An Authentication object was not found in the SecurityContext", 'Bearer', 'UAA/client'
        )
      else
        raise "Don't know how to handle #{type_string.inspect} authentication."
      end
    end
  end


  helpers do
    def logger
      settings.logger
    end
  end

  configure do
    Aok::Config::Strategy.initialize_strategy
    Aok::Config.initialize_database
    set :public_folder, File.expand_path('../../public', __FILE__)
    logger.debug "Serving static files from #{settings.public_folder.inspect}"
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
      instance = klass.new(self, middleware_options)

      # Fake out Rack to think we're on the auth callback with our synthesized form body
      path = instance.callback_path

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
      instance.call!(env)
    end
  end

end
