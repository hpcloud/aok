require 'time'
require 'uaa'
class UaaController < ApplicationController
  attr_reader :security_context

  before do
    @security_context = Aok::SecurityContext.new(request)
  end

  helpers do
    def authenticate!
      return if security_context.authenticated?
      raise Aok::Errors::Unauthorized.new(
        "An Authentication object was not found in the SecurityContext", 'Basic', 'UAA/client'
      )
    end
  end

  get '/?' do
    return 'Hello World'
  end

  get '/login' do
    return 200,
      {"Content-Type" => "application/json"},
      # TODO: this should return information about the configured strategy instead
      # of this generic info.
      { :timestamp => Time.now.xmlschema,
        :commit_id => AppConfig[:commit_id],
        :prompts => {
          :username => ["text","Username"],
          :password => ["password","Password"]
        }
      }.to_json
  end

  post '/oauth/token' do
    Rack::OAuth2::Server::Token.new do |req, resp|
      authenticate!
      client = security_context.client
      scopes = validate_scope(req, client)
      validate_grant_type req, client
      resp.access_token = AccessToken.create(:client => client, :scopes => scopes).to_bearer_token

    end.call(env)
  end

  get_and_post '/oauth/authorize' do
    allow_approval = request.request_method == 'POST'
    oauth_resp = Rack::OAuth2::Server::Authorize.new do |req, res|
      client = Client.find_by_identifier(req.client_id) || req.bad_request!('Client not found')
      find_identity do |identity|
        raise(Aok::Errors::Unauthorized.new) unless identity
        res.redirect_uri = @redirect_uri = req.verify_redirect_uri!(client.redirect_uri)
        scopes = validate_scope(req, client, identity)
        if allow_approval
          if params[:response_type]
            case req.response_type
            # when :code
            #   authorization_code = identity.authorization_codes.create(:client => client, :redirect_uri => res.redirect_uri)
            #   res.code = authorization_code.token
            when :token
              res.access_token = identity.access_tokens.create(:client => client, :scopes => scopes).to_bearer_token
            end
            res.approve!
          else
            req.access_denied!
          end
        else
          @response_type = req.response_type
        end
      end
    end.call(env)

    respond *oauth_resp
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
      logger.debug "scopes_to_grant = #{user_scopes} ? (#{user_scopes & requested_scopes}) : #{requested_scopes}"
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
    end

  end
end