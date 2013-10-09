class ClientsController < ApplicationController

  # List Clients
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#list-clients-get-oauthclients
  get '/?' do
    raise Aok::Errors::NotImplemented
  end

  # Inspect Client
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#inspect-client-get-oauthclientsclient_id
  # TODO: what should permissions be for this call?
  get "/:identifier" do
    #authenticate!  #TODO FIXME
    client = Client.find_by_identifier params[:identifier]
    return 404 unless client
    return {
      :client_id => client.identifier,
      :scope => client.scope,
      :resource_ids => client.scope.split(',').collect{|s|s.split('.').last}.join(','), #TODO: verify what this is supposed to be
      :authorities => client.authorities,
      :authorized_grant_types => client.authorized_grant_types
    }.to_json
  end

  # Register Client
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#register-client-post-oauthclientsclient_id
  # TODO: What should permissions be for this call?
  post "/?" do
    cd = read_json_body
    logger.debug "Client detail passed to POST /oauth/clients: #{cd.inspect}"
    #authenticate! #TODO FIXME
    c = Client.new
    #TODO: instead of joining these here, use a helper method in the
    #authorities module to properly assign list values
    c.scope = cd['scope'].join(',')
    c.identifier = c.name = cd['client_id']
    c.secret = cd['client_secret']
    c.authorized_grant_types = cd['authorized_grant_types'].join(',')
    c.authorities = cd['authorities'].join(',')
    # TODO: what are the resource ids for?
    #c.resource_ids = cd['resource_ids'].join(',')
    #c.redirect_uri = cd['redirect_uri']
    #c.access_token_validity = cd['access_token_validity']
    #c.refresh_token_validity = cd['refresh_token_validity']
    c.save!
    return 201,
      {
        :client_id => c.identifier,
        :scope => c.scope,
        :resource_ids => c.scope.split(',').collect{|s|s.split('.').last}.join(','), #TODO: verify what this is supposed to be
        :authorities => c.authorities,
        :authorized_grant_types => c.authorized_grant_types
      }.to_json
  end


  # Update Client
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#update-client-put-oauthclientsclient_id
  put '/:identifier' do
    raise Aok::Errors::NotImplemented
  end

  # Delete Client
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#delete-client-delete-oauthclientsclient_id
  delete '/:identifier' do
    raise Aok::Errors::NotImplemented
  end

  # Change Client Secret
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#change-client-secret-put-oauthclientsclient_idsecret
  put '/:identifier/secret' do
    raise Aok::Errors::NotImplemented
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
