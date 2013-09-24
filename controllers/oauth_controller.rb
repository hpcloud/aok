class OauthController < ApplicationController
  # This is needed in order to process direct_login in this controller
  include LoginEndpoint


  # Client Obtains Token
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#client-obtains-token-post-oauthtoken
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#oauth2-token-endpoint-post-oauthtoken
  #
  # TODO: This currently only supports an undocumented client access token grant using
  # basic auth that is implemented in UAA and required by cf. Needs more investigation.
  post '/token' do
    Rack::OAuth2::Server::Token.new do |req, resp|
      authenticate!(:basic)
      client = security_context.client
      scopes = validate_scope(req, client)
      grant_type = validate_grant_type req, client
      token = case grant_type
      when :client_credentials
        AccessToken.new(:client => client, :scopes => scopes)
      else
        raise "Unsupported grant_type #{grant_type.inspect}"
      end
      resp.access_token = token.to_bearer_token
      token.save!

    end.call(env)
  end

  # Note: UAA has overloaded this endpoint
  #
  # Browser Requests Code
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#browser-requests-code-get-oauthauthorize
  #
  # Implicit Grant for Browsers
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#implicit-grant-for-browsers-get-oauthauthorize
  get '/authorize', :provides => :html do
    require_user
    raise Aok::Errors::NotImplemented
  end

  # Non-Browser Requests Code
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#non-browser-requests-code-get-oauthauthorize
  get '/authorize', :provides => :json do
    raise Aok::Errors::NotImplemented
  end

  # Implicit Grant with Credentials
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#implicit-grant-with-credentials-post-oauthauthorize
  #
  # UAA defines the following overload also, which we will probably not implement in AOK
  # Trusted Authentication from Login Server
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#trusted-authentication-from-login-server
  post '/authorize', :provides => :json do
    oauth_resp = Rack::OAuth2::Server::Authorize.new do |req, res|
      client = Client.find_by_identifier(req.client_id) || req.bad_request!('Client not found')
      find_identity do |identity|
        raise(Aok::Errors::Unauthorized.new) unless identity
        res.redirect_uri = @redirect_uri = req.verify_redirect_uri!(client.redirect_uri)
        scopes = validate_scope(req, client, identity)
        if params[:response_type]
          case req.response_type
          # when :code
          #   authorization_code = identity.authorization_codes.create(:client => client, :redirect_uri => res.redirect_uri)
          #   res.code = authorization_code.token
          when :token
            res.access_token = identity.access_tokens.create(:client => client, :scopes => scopes).to_bearer_token
          else
            raise "Unsupported response_type #{req.response_type.inspect}"
          end
          res.approve!
        else
          req.access_denied!
        end
      end
    end.call(env)

    respond(*oauth_resp)
  end

  # Oauth2 Authorization
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#oauth2-authorization-post-oauthauthorizeuser_oauth_approvaltrue
  # Query string must be ?user_oauth_approval=true
  post '/authorize', :provides => :html do
    raise Aok::Errors::NotImplemented
  end

  # This endpoint is used in the integration tests
  post '/authorize', :provides => 'application/x-www-form-urlencoded' do
    raise Aok::Errors::NotImplemented
  end

  # OAuth2 Authorization Confirmation
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#oauth2-authorization-confirmation-get-oauthauthorizeconfirm_access
  get '/authorize/confirm_access', :provides => :html do
    raise Aok::Errors::NotImplemented
  end

  helpers do
    def respond(status, header, response)
      if env['aok.finishable_error']
        return env['aok.finishable_error'].finish
      end

      ["WWW-Authenticate"].each do |key|
        headers[key] = header[key] if header[key].present?
      end
      if response.redirect?
        redirect header['Location'], 302
      else
        raise "Shouldn't have gotten here, response was #{response.inspect}"
      end
    end

    def find_identity &block
      # cf-uaac passes creds as top-level, but UAA test suite uses json under :credentials
      if params[:credentials]
        creds = JSON.parse(params[:credentials])
        username = creds['username']
        password = creds['password']
      else
        username = params[:username]
        password = params[:password]
      end
      direct_login(username, password, &block)
    end

    def validate_scope req, client, identity=nil
      requested_scopes = determine_scopes req, client
      user_scopes = identity ? identity.authorities_list_with_defaults : nil

      scopes_to_grant = user_scopes ? (user_scopes & requested_scopes) : requested_scopes
      if scopes_to_grant.blank? && !client.authorities.blank?
        req.invalid_scope!("Invalid scope (empty) - this user is not allowed
          any of the requested scopes: #{requested_scopes.join(', ')} (either you requested
          a scope that was not allowed or client '#{client.identifier}' is not allowed to
          act on behalf of this user)".gsub(/\s+/,' '))
      end

      available_scopes = get_available_scopes(req, client)
      invalid_scopes = requested_scopes - available_scopes
      if !invalid_scopes.empty?
        req.invalid_scope!("Invalid scopes: #{invalid_scopes.join(', ')}.
          Did you know that you can get default scopes by simply sending
          no value?".gsub(/\s+/,' '),
          :redirect_uri => client.redirect_uri,
          :protocol_params_location => params)
      end
      return scopes_to_grant
    end

    def determine_scopes req, client
      requested_scopes = req.scope

      if requested_scopes.blank?
        requested_scopes = get_available_scopes req, client
      end

      return requested_scopes
    end

    def get_available_scopes req, client
      if req.respond_to?(:grant_type)
        case req.grant_type
        when :client_credentials
          client.authorities_list
        else
          raise "unknown grant type #{req.grant_type.inspect}"
        end
      else
        client.scope_list
      end
    end

    def validate_grant_type req, client
      unless client.valid_grant_type?(req.grant_type)
        req.invalid_grant_type!
      end
      return req.grant_type
    end

  end

end
