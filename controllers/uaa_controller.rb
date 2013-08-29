require 'time'
require 'uaa'
class UaaController < ApplicationController

  get '/?' do
    return 'Hello World'
  end

  get '/login' do
    return 200,
      {"Content-Type" => "application/json"},
      { :timestamp => Time.now.xmlschema,
        # TODO: move this commit to memory instead of reading the file
        :commit_id => File.read(File.dirname(__FILE__) + '/../GITDESCRIBE-PKG').strip,
        :prompts => {
          :username => ["text","Username"],
          :password => ["password","Password"]
        }
      }.to_json
  end

  # post '/oauth/token' do 
  #   # params =~ {"grant_type"=>"password", "username"=>"bob_johnson", "password"=>"zyzzyva"}
  #   return 200, 
  #     {'Content-Type' => 'application/json'}, 
  #     {
  #       :token_type => 'bearer', 
  #       :access_token => CF::UAA::TokenCoder.encode(
  #         {
  #           :aud => 'cloud_controller',
  #           :user_id => 'abc-1234',
  #           :email => 'stackato@stackato.com',
  #           :exp => Time.now.to_i + 1_000_000_000
  #         }, 
  #         {
  #           :skey => 'tokensecret'
  #         }
  #       )
  #     }.to_json
  # end

  get_and_post '/oauth/authorize' do 
    allow_approval = request.request_method == 'POST'
    respond *(Rack::OAuth2::Server::Authorize.new do |req, res|
      client = Client.find_by_identifier(req.client_id) || req.bad_request!
      find_identity do |identity|
        raise(Aok::Errors::Unauthorized.new) unless identity
        res.redirect_uri = @redirect_uri = req.verify_redirect_uri!(client.redirect_uri)
        scopes = validate_scope(req, client, identity)
        if allow_approval
          if params[:response_type]
            case req.response_type
            when :code
              authorization_code = identity.authorization_codes.create(:client => client, :redirect_uri => res.redirect_uri)
              res.code = authorization_code.token
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
    end.call(env))
  end    

  private

  def respond(status, header, response)
    ["WWW-Authenticate"].each do |key|
      headers[key] = header[key] if header[key].present?
    end
    if response.redirect?
      redirect header['Location'], 302
    else
      erb :new
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

  def validate_scope req, client, identity
    requested_scopes = determine_scopes client
    user_scopes = parse_scope_list(identity.authorities)
    
    scopes_to_grant = user_scopes & requested_scopes

    if scopes_to_grant.blank? && !client.authorities.blank?
      req.invalid_scope!("Invalid scope (empty) - this user is not allowed 
        any of the requested scopes: #{invalid_scopes.join(', ')} (either you requested 
        a scope that was not allowed or client '#{client.identifier}' is not allowed to 
        act on behalf of this user)".gsub(/\s+/,' '))
    end

    available_scopes = get_available_scopes(client)
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

  def determine_scopes client
    requested_scopes = parse_scope_list(params[:scope])
    if requested_scopes.blank?
      requested_scopes = parse_scope_list(client.authorities)
    end

    return requested_scopes
  end

  def get_available_scopes client
    parse_scope_list(client.authorities)
  end

  def parse_scope_list scopes
    return [] if scopes.blank?
    return scopes.split(',').uniq
  end

end