module Aok
  class SecurityContext
    attr_reader :authentication

    def initialize(request)
      auth ||=  Rack::Auth::Basic::Request.new(request.env)
      return unless auth.provided?
      @authentication = Authentication.new
      @authentication.type = if auth.basic?
        basic_auth(auth)
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
      key, client_config = AppConfig[:oauth][:clients].detect{|key, client|client[:id]==username}
      return unless client_config && client_config[:secret]
      return unless password == client_config[:secret]
      @authentication.username = username
      @authentication.client = Client.find_by_identifier(client_config[:id])
    end

  end

  class Authentication
    attr_accessor :username, :type, :client

    def authenticated?
      !client.nil?
    end
  end
end