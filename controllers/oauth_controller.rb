class OauthController < ApplicationController
  # This is needed in order to process direct_login in this controller
  include LoginEndpoint


  # Client Obtains Token
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#client-obtains-token-post-oauthtoken
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#oauth2-token-endpoint-post-oauthtoken
  post '/token' do
    Rack::OAuth2::Server::Token.new do |req, resp|
      authenticate!(:basic)
      client = security_context.client
      grant_type = validate_grant_type req, client
      case grant_type
      when :client_credentials
        scopes = validate_scope(req, client)
        resp.access_token = AccessToken.create!(:client => client, :scopes => scopes).to_bearer_token
      when :password
        identity = Identity.authenticate(req.username, req.password) || req.invalid_grant!
        scopes = validate_scope(req, client, identity)
        resp.access_token = AccessToken.create!(:client => client, :scopes => scopes, :identity => identity).to_bearer_token(:with_refresh_token)
      when :authorization_code
        code = AuthorizationCode.valid.find_by_token(req.code)
        req.invalid_grant! if code.blank? || code.redirect_uri != req.redirect_uri
        scopes = validate_scope(req, client, code.identity)
        resp.access_token = code.access_token(scopes).to_bearer_token(:with_refresh_token)
      when :refresh_token
        refresh_token = client.refresh_tokens.valid.find_by_token(req.refresh_token)
        req.invalid_grant! unless refresh_token
        resp.access_token = refresh_token.access_tokens.create.to_bearer_token
      else
        logger.debug "Unsupported grant_type #{grant_type.inspect}"
        req.unsupported_grant_type!
      end

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
    oauth_authorize(current_user)
  end

  # Non-Browser Requests Code
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#non-browser-requests-code-get-oauthauthorize
  get '/authorize', :provides => :json do
    raise Aok::Errors::NoGettingCredentials if params[:credentials]

    require_user
    oauth_authorize(current_user)
  end

  # Implicit Grant with Credentials
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#implicit-grant-with-credentials-post-oauthauthorize
  #
  # UAA defines the following overload also, which we will probably not implement in AOK
  # Trusted Authentication from Login Server
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#trusted-authentication-from-login-server
  post '/authorize', :provides => %W{application/x-www-form-urlencoded json} do
    oauth_authorize
  end

  # Oauth2 Authorization
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#oauth2-authorization-post-oauthauthorizeuser_oauth_approvaltrue
  # Query string must be ?user_oauth_approval=true
  post '/authorize', :provides => :html do
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
        redirect to(header['Location']), 302
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
      user_scopes = identity ? identity.authorities_list : nil

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
        msg = "Invalid scopes: #{invalid_scopes.join(', ')}.
          Did you know that you can get default scopes by simply sending
          no value?".gsub(/\s+/,' ')
        msg << " You requested a scope containing a comma. Are you sure?
          When requesting multiple scopes, they should be separated with
          spaces, not commas.".gsub(/\s+/,' ') if invalid_scopes.any?{|s|s.include?(',')}
        req.invalid_scope!(msg,
          :redirect_uri => client.redirect_uri,
          :protocol_params_location => params)
      end
      return scopes_to_grant
    end

    def determine_scopes req, client
      requested_scopes = req.scope
      # bod = request.body.read
      # logger.debug "Req body: #{bod.inspect}"
      # logger.debug "Real requested scopes is #{requested_scopes.inspect}"
      unless requested_scopes.kind_of? Array
        raise "requested_scopes must be an array. but was #{requested_scopes.inspect}"
      end

      if requested_scopes.blank?
        requested_scopes = get_available_scopes req, client
      end

      # logger.debug "De facto requested scopes is #{requested_scopes.inspect}"
      return requested_scopes
    end

    def get_available_scopes req, client
      available_scopes = if req.respond_to?(:grant_type)
        case req.grant_type
        when :client_credentials
          client.authorities_list
        when :password, :authorization_code
          client.scope_list
        else
          raise "unknown grant type #{req.grant_type.inspect}"
        end
      else
        client.scope_list
      end
      # logger.debug "Available scopes for #{req.grant_type} grant type is #{available_scopes.inspect}"
      return available_scopes
    end

    def validate_grant_type req, client
      unless client.valid_grant_type?(req.grant_type)
        req.invalid_grant_type!
      end
      return req.grant_type
    end

    def oauth_authorize(identity=nil)
      oauth_resp = Rack::OAuth2::Server::Authorize.new do |req, res|
        client = Client.find_by_identifier(req.client_id) || req.bad_request!('Client not found')
        core = Proc.new do
          raise(Aok::Errors::Unauthorized.new) unless identity
          # TODO: The next line allows clients without pre-registered redirect_uri, which is allowed
          # by the oauth2 spec, but not directly supported by rack-oauth2, and probably not a good idea
          # It's allowed here because the UAA java integration tests rely on this behavior.
          res.redirect_uri = @redirect_uri = req.verify_redirect_uri!(client.redirect_uri || req.redirect_uri)
          scopes = validate_scope(req, client, identity)
          if params[:response_type]
            case req.response_type
            when :code
              authorization_code = identity.authorization_codes.create(:client => client, :redirect_uri => res.redirect_uri)
              res.code = authorization_code.token
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
        if identity
          core.call
        else
          find_identity do |i|
            identity = i
            core.call
          end
        end
      end.call(env)

      respond(*oauth_resp)
    end

  end

end
