require 'logger'
require 'kato/local/node'

class ApplicationController < Sinatra::Base
  helpers ApplicationHelper, CurrentUserHelper, ErrorHandlingHelper

  set :raise_errors, true # throw exceptions up the rack stack
  set :show_exceptions, false # disable html error pages
  set :dump_errors, false # disable stack traces for handled errors

  # IP Spoofing protection isn't that helpful and
  # causes a lot of warnings in the log
  disabled_protection = [:ip_spoofing]
  disabled_protection << :json_csrf if File.exist?('/s/code/console/DEV_MODE')
  set :protection, :except => disabled_protection

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

  configure :development, :test do
    # The normal Sinatra logger
    set :logging, Logger::DEBUG

    # This is another logger for use in the Application scope
    logger = Logger.new $stdout
    logger.level = Logger::DEBUG
    logger.datetime_format = '%a %d-%m-%Y %H%M '
    set :logger, logger
    $stdout.sync = true
    OmniAuth.config.logger = logger

    # This is another logger for AR so we don't have
    # to see all those SQL statements
    ar_logger = Logger.new $stdout
    ar_logger.level = Logger::INFO
    ar_logger.datetime_format = '%a %d-%m-%Y %H%M '
    ActiveRecord::Base.logger = ar_logger
  end

  configure do
    filepath = File.join(File.dirname(File.expand_path(__FILE__)), '..', 'config', 'path_rules.yml')
    path_rules = UaaSpringSecurityUtils::PathRules.new(filepath)
    path_rules.logger = logger
    set :path_rules, path_rules
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
    logger.debug "Security context principal: #{security_context.principal.inspect}"
    check_security
  end

  helpers do
    WHITELIST = /\A\/uaa((\/?)|(\/oauth\/uaa\/login\.do)|(\/logout.do)|(\/oauth\/authorize)|(\/auth\/failure))\z/
    def check_security
      path_rule = settings.path_rules.match_path(request)
      # logger.debug "Matched path: #{path_rule.to_s}"

      if path_rule.nil?
        raise Aok::Errors::Unauthorized.new("Unauthorized: Unknown path")
      end

      if !path_rule.security?
        # no security! whee!
        logger.debug "No security for path #{request.path}"
        return
      end

      pass = path_rule.authorized?(security_context)

      return if pass

      # ignoring failure if on login path, since we handle this in the route
      if path_rule['custom-filter'].kind_of?(Hash) &&
          path_rule['custom-filter']['position'] == "FORM_LOGIN_FILTER"
        logger.debug "Ignoring auth failure since this is an auth entry point"
        return
      end

      if path_rule['access-denied-page']
        # Whitelisting a couple paths that have their own auth
        if request.path =~ WHITELIST
          logger.debug "Path #{request.path} whitelisted..."
          return
        end
        logger.debug "#{request.path} NOT whitelisted..."
        logger.debug "Access denied page: #{path_rule['access-denied-page'].inspect} for access denial"
        # XXX Not really sure what is supposed to happen here. Redirecting to / causes a loop
        raise Aok::Errors::AccessDenied.new('You are not allowed to access this resource.')
      end

      # everything from here on is failure-handling
      handler = path_rule['access-denied-handler']['class']
      logger.debug "Should use #{handler.inspect} to handle denial"
      case handler
      when /\.OAuth2AccessDeniedHandler$/
        UaaSpringSecurityUtils::OAuth2AccessDeniedHandler.handle(path_rule, security_context)
      else
        raise 'no access-denied-handler found'
      end

      # Catchall
      raise Aok::Errors::AccessDenied.new('Unauthorized via Spring Security rules')
    end

    # authenticate(type=:oauth2)
    def authenticate!(*args)
      type = :oauth2
      if !args.blank?
        if [Symbol, String].include?(args.first.class)
          type_string = args.shift.to_s.downcase
          type = if type_string == 'basic'
            :basic
          elsif type_string =~ /^oauth2/
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
        "aok.block" => block # call the block (if provided) with the login result
      )

      # Call the middleware, which will then call up in to the auth code
      # in ApplicationController. The results can be returned directly.
      instance.call!(env)
    end
  end

end
