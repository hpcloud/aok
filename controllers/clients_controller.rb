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
  post "/?" do
    client_details = read_json_body
    resp, success = client_create(client_details)
    code = if success
      201
    else
      (resp[:error_description] && resp[:error_description] =~ /identifier.+?taken/i) ? 409 : 400
    end
    return code, resp.to_json
  end

  def set_client_details(client, client_details, allow_secret = false)
    #TODO: instead of joining these here, use a helper method in the
    #authorities module to properly assign list values
    client.scope = client_details['scope'].join(',')
    client.identifier = client.name = client_details['client_id']
    client.secret = client_details['client_secret'] if allow_secret
    client.authorized_grant_types = client_details['authorized_grant_types'].join(',')
    if client_details['authorities'].kind_of? Array
      client.authorities = client_details['authorities'].join(',')
    end
    client.redirect_uri = client_details['redirect_uri']

    # TODO: once we have schema for this, store in the db
    #client.access_token_validity = client_details['access_token_validity']
    #client.refresh_token_validity = client_details['refresh_token_validity']
  end

  # Update Client
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#update-client-put-oauthclientsclient_id
  put '/:identifier' do
    cd = read_json_body
    resp, success = client_update(cd, params[:identifier])
    return success ? 200 : 400, resp.to_json
  end

  # Delete Client
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#delete-client-delete-oauthclientsclient_id
  delete '/:identifier' do
    resp, success = client_delete(params[:identifier])
    return success ? 200 : 400, resp.to_json
  end

  # Change Client Secret
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#change-client-secret-put-oauthclientsclient_idsecret
  put '/:identifier/secret' do
    secret_details = read_json_body
    client = Client.find_by_identifier params[:identifier]
    raise Aok::Errors::NotFound.new("Client not found.") unless client
    unless client.authenticate(secret_details['oldSecret'])
      raise Aok::Errors::AokError.new 'unauthorized', 'oldSecret is incorrect', 401
    end
    client.secret = secret_details['secret']
    if client.save
      return 200, {'status' => 'saved'}.to_json
    else
      handle_save_error(client).to_json
    end
  end

  # Register, update or delete Multiple Clients: POST /oauth/clients/tx/modify
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#register-update-or-delete-multiple-clients-post-oauthclientstxmodify
  post '/tx/modify' do
    response_details = nil
    tx_success = true
    Client.transaction do
      clients_details = read_json_body
      response_details = clients_details.collect do |client_details|
        case client_details['action']
        when 'add'
          resp, success = client_create(client_details)
          tx_success &= success
          resp
        when 'update'
          resp, success = client_update(client_details)
          tx_success &= success
          resp
        when 'delete'
          resp, success = client_delete(client_details['client_id'])
          tx_success &= success
          resp
        else
          logger.debug "unknown action #{client_details['action'].inspect}"
          raise Aok::Errors::NotImplemented
        end
      end
      raise ActiveRecord::Rollback unless tx_success
    end
    return tx_success ? 200 : 400, response_details.to_json
  end

  # Change Multiple Client Secrets: POST /oauth/clients/tx/secret
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#change-multiple-client-secrets-post-oauthclientstxsecret
  post '/tx/secret' do
    raise Aok::Errors::NotImplemented
  end

  # Register Multiple Clients: POST /oauth/clients/tx
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#register-multiple-clients-post-oauthclientstx
  post '/tx' do
    response_details = nil
    tx_success = true
    Client.transaction do
      clients_details = read_json_body
      response_details = clients_details.collect do |client_details|
        resp, success = client_create(client_details)
        tx_success &= success
        resp
      end
      raise ActiveRecord::Rollback unless tx_success
    end

    return tx_success ? 201 : 400, response_details.to_json
  end

  # Update Multiple Clients: PUT /oauth/clients/tx
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#update-multiple-clients-put-oauthclientstx
  put '/tx' do
    response_details = nil
    tx_success = true
    Client.transaction do
      clients_details = read_json_body
      response_details = clients_details.collect do |client_details|
        resp, success = client_update(client_details)
        tx_success &= success
        resp
      end
      raise ActiveRecord::Rollback unless tx_success
    end
    return tx_success ? 200 : 400, response_details.to_json
  end

  def client_create(client_details)
    client = Client.new
    set_client_details client, client_details, :allow_secret
    if client.save
      return client_hash(client), true
    else
      return handle_save_error(client), false
    end
  end

  def client_update(client_details, identifier=nil)
    identifier ||= client_details['client_id']
    client = Client.find_by_identifier identifier.to_s
    raise Aok::Errors::NotFound.new("Client #{identifier} does not exist") unless client
    set_client_details client, client_details
    if client.save
      return client_hash(client), true
    else
      return handle_save_error(client), false
    end
  end

  def client_delete(identifier)
    client = Client.find_by_identifier identifier.to_s
    logger.debug "Client #{identifier} does not exist"
    raise Aok::Errors::NotFound.new("Client #{identifier} does not exist") unless client
    client.destroy
    return client_hash(client), true
  end    

  def handle_save_error(client)
    return  {
      :error => "invalid_#{client.class.name.underscore}",
      :error_description => client.errors.full_messages.join('. ')
    }
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
