class ClientsController < ApplicationController

  # List Clients
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#list-clients-get-oauthclients
  get '/?' do
    Client.all.collect do |client|
      client_hash client
    end.to_json
  end

  # Inspect Client
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#inspect-client-get-oauthclientsclient_id
  # TODO: what should permissions be for this call?
  get "/:identifier" do
    client = Client.find_by_identifier params[:identifier]
    raise Aok::Errors::NotFound.new("Client not found.") unless client
    return client_hash(client).to_json
  end

  def client_hash(client)
    {
      :client_id => client.identifier,
      :scope => client.scope,
      :resource_ids => client.scope_list.collect{|s|s.split('.').last}.join(','), #TODO: verify what this is supposed to be
      :authorities => client.authorities,
      :authorized_grant_types => client.authorized_grant_types_list,
      :refresh_token_validity => client.refresh_token_validity,
      :access_token_validity => client.access_token_validity
    }
  end

  # Register Client
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#register-client-post-oauthclientsclient_id
  # TODO: What should permissions be for this call?
  post "/?" do
    client_details = read_json_body
    client = Client.new
    set_client_details client, client_details, :allow_secret
    if client.save
      return 201, client_hash(client).to_json
    else
      handle_save_error client
    end
  end

  def set_client_details(client, client_details, allow_secret = false)
    #TODO: ClientAdminEndpointsIntegrationTests implies that you should
    # be able to set arbitrary fields on clients. For instance, they send
    # "foo": "rab" in the json to PUT. What's the functionality of that
    # supposed to be? Do we want to support that?

    #TODO: instead of joining these here, use a helper method in the
    #authorities module to properly assign list values
    client.scope = client_details['scope'].join(',')
    client.identifier = client.name = client_details['client_id']
    client.secret = client_details['client_secret'] if allow_secret
    client.authorized_grant_types = client_details['authorized_grant_types'].join(',')
    client.authorities = client_details['authorities'].join(',')
    client.redirect_uri = client_details['redirect_uri']

    # TODO: once we have schema for this, store in the db
    #client.access_token_validity = client_details['access_token_validity']
    #client.refresh_token_validity = client_details['refresh_token_validity']
  end

  # Update Client
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#update-client-put-oauthclientsclient_id
  put '/:identifier' do
    cd = read_json_body
    client = Client.find_by_identifier params[:identifier]
    raise Aok::Errors::NotFound.new("Client not found.") unless client
    set_client_details client, cd
    if client.save
      return 200, client_hash(client).to_json
    else
      handle_save_error client
    end
  end

  # Delete Client
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#delete-client-delete-oauthclientsclient_id
  delete '/:identifier' do
    client = Client.find_by_identifier params[:identifier]
    raise Aok::Errors::NotFound.new("Client not found.") unless client
    client.destroy
    return
  end

  # Change Client Secret
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#change-client-secret-put-oauthclientsclient_idsecret
  put '/:identifier/secret' do
    secret_details = read_json_body
    client = Client.find_by_identifier params[:identifier]
    raise Aok::Errors::NotFound.new("Client not found.") unless client
    # TODO: Gotta make the client secret a hash in the db
    if secret_details['oldSecret'] != client.secret
      raise Aok::Errors::AokError.new 'unauthorized', 'oldSecret is incorrect', 401
    end
    client.secret = secret_details['secret']
    if client.save
      # TODO: API docs say to return "a status message (hash)" wtf is that?
      return 200, {'status' => 'saved'}.to_json
    else
      handle_save_error client
    end

  end

  def handle_save_error client
    status((client.errors[:identifier] && client.errors[:identifier].any?{|e|e =~ /taken/}) ? 409 : 400)
    return  {
      :error => "invalid_#{client.class.name.underscore}",
      :error_description => client.errors.full_messages.join('. ')
    }.to_json
  end

  # List Tokens for Client
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#list-tokens-for-client-get-oauthclientsclient_idtokens
  get ':identifier/tokens' do
    raise Aok::Errors::NotImplemented
  end

  # Revoke Token by Client
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#revoke-token-by-client-delete-oauthclientsclient_idtokensjti
  delete ':identifier/tokens/:jti' do
    raise Aok::Errors::NotImplemented
  end

end
