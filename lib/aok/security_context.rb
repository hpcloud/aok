module Aok
  class SecurityContext
    attr_reader :authentication

    def initialize(request)
      auth ||=  Rack::Auth::Basic::Request.new(request.env)
      return unless auth.provided?
      @authentication = Authentication.new
      @authentication.type = if auth.basic?
        basic_auth(auth)
        :basic
      else
        nil
      end
    end

    def authenticated?
      authentication.authenticated?
    end

    def client
      authentication.client
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
      @authentication.username = username
      @authentication.client = client
    end

    def logger
      ApplicationController.logger
    end

  end

  class Authentication
    attr_accessor :username, :type, :client

    def authenticated?
      !client.nil?
    end
  end
end