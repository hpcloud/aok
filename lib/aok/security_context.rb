module Aok

  # Authentication comes in 3 flavors:
  # * HTTP Basic auth is used for certain system services
  # * OAuth User tokens are used by users interactive with the system
  # * OAuth Client tokens are used by authorized 3rd-party system (like cc_ng)
  #
  class SecurityContext
    attr_reader :authentication, :request
    BASIC = 'Basic'
    OAUTH2_USER = 'OAuth2 User'
    OAUTH2_CLIENT = 'OAuth2 Client'

    def initialize(request)
      @authentication = Authentication.new
      @request = request
      basic = Rack::Auth::Basic::Request.new(request.env)
      if basic.provided? && basic.basic?
        basic_auth(basic)
      elsif oauth2?
        token_auth
      end
    end

    def authenticated?
      authentication.authenticated?
    end

    def access_token
      request.env[Rack::OAuth2::Server::Resource::ACCESS_TOKEN]
    end

    def client
      authentication.client
    end

    def oauth2?
      !!access_token
    end

    private

    def basic_auth(auth)
      return unless auth.credentials
      username, password = auth.credentials
      logger.debug "Basic authentication attempt with username #{username.inspect} and password #{password.inspect}" #TODO: don't log password
      client = Client.find_by_identifier username
      unless client
        logger.debug "Client #{username.inspect} not found"
        return
      end
      unless client.secret
        logger.debug "Client #{username.inspect} doesn't have a secret to authenticate"
        return
      end
      unless password == client.secret
        logger.debug "Password doesn't match client secret"
        return
      end
      logger.debug "Basic auth successful"
      authentication.client = client
      authentication.type = BASIC
    end

    def token_auth
      unless authentication.token = AccessToken.valid.find_by_token(access_token)
        raise Rack::OAuth2::Server::Resource::Bearer::Unauthorized.new(:invalid_token)
      end
      authentication.identity = authentication.token.identity
      authentication.client = authentication.token.client
      if authenticated?
        authentication.type = authentication.client ? OAUTH2_CLIENT : OAUTH2_USER
      end
    end

    def logger
      ApplicationController.logger
    end

  end

  class Authentication
    attr_accessor :identity, :type, :client, :token

    def authenticated?
      identity || client
    end

    def basic?
      type == Aok::SecurityContext::BASIC
    end

    def oauth2?
      type == Aok::SecurityContext::OAUTH2_USER || type == Aok::SecurityContext::OAUTH2_CLIENT
    end
  end
end