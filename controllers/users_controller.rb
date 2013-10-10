class UsersController < ApplicationController

        # XXX Test only methods:
        # Reset -- delete all users
        get '/RESET/' do
          Identity.delete_all
          return
        end

        get '/SETUP/' do
          Identity.new(
            :given_name => 'Ingy',
            :family_name => 'dot Net',
          ).save!
        end
        # TODO Move these to test-only class.

  # Create a User
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#create-a-user-post-users
  # http://www.simplecloud.info/specs/draft-scim-core-schema-01.html#user-resource
  post '/?' do
    # TODO: Authentication, Validation, robustification
    json = read_json_body
    user = Identity.new
    user.family_name = json['name']['familyName'] rescue nil
    user.given_name = json['name']['givenName'] rescue nil
    user.username = json['userName']
    user.password = user.password_confirmation = json['password'] rescue nil

    # TODO: support multiple emails
    user.email = json['emails'].first['value'] rescue nil
    user.save!

    scim_user_response user
  end

  # Get a specific User by guid
  # This isn't actually in the spec, but should probably return the same JSON
  # aas create User.
  get '/:id' do
    id = params[:id]
    user = Identity.find_by_guid(id)
    scim_user_response user
  end

  def scim_user_response user
    user_data = {
      'schemas' => ['urn:scim:schemas:core:1.0'],
      'externalId' => user.username,
      'meta' => {
        'version' => 0,
        'created' => user.created_at,
        'lastModified' => user.updated_at,
      },
    }

    f = user.family_name
    g = user.given_name
    if f or g
      n = user_data['name'] = {}
      n['familyName'] = f if f
      n['givenName'] = g if g
    end
    user_data['userName'] = user.username
    user_data.to_json
  end

  # Update a User
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#update-a-user-put-usersid
  put '/:id' do
    raise Aok::Errors::NotImplemented
  end

  # Delete a User
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#delete-a-user-delete-usersid
  delete '/:id' do
    # authenticate! :oauth2
    guid=params[:id] # TODO validate this
    user = Identity.find_by_guid(guid)
    Identity.delete(user.id)
  end

  # Change Password
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#change-password-put-usersidpassword
  put '/:id/password' do
    raise Aok::Errors::NotImplemented
  end

  # Query for information
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#query-for-information-get-users
  # http://www.simplecloud.info/specs/draft-scim-api-01.html#query-resources
  # http://tools.ietf.org/html/draft-ietf-scim-core-schema-02#section-12
  # TODO: support pagination, etc..
  # TODO: authentication
  get '/?' do
    begin
      filter = if params[:filter]
        Aok::Scim::ActiveRecordQueryBuilder.new.build_query(params[:filter])
      else
        true
      end
    rescue
      # XXX This error doesn't show up in logs
      raise Aok::Errors::ScimFilterError.new($!.message)
    end
    identities = Identity.where(filter)
    resources = []
    identities.each do |identity|
      resources.push({
        "id" => identity.guid,
        "userName" => identity.username,
        "emails" => [
          {"value" => identity.email}
        ],
        "name" => {
          "givenName" => identity.given_name,
          "familyName" => identity.family_name
        },
        "groups" => []
      })
    end

    return {
      'schemas' => ["urn:scim:schemas:core:1.0"],
      'totalResults' => 0,
      'resources' => resources,
      'totalResults' => resources.size
    }.to_json

  end

  # Delete a User
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#delete-a-user-delete-usersid
  delete '/:id' do
    raise Aok::Errors::NotImplemented
  end


  def user_xrds
    types = [
             OpenID::OPENID_2_0_TYPE,
             OpenID::OPENID_1_0_TYPE,
             OpenID::SREG_URI,
            ]

    render_xrds(types)
  end


end
