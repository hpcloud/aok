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
    i = Identity.new
    i.family_name = json['name']['familyName'] rescue nil
    i.given_name = json['name']['givenName'] rescue nil
    i.username = json['userName']
    i.password = i.password_confirmation = json['password'] rescue nil

    # TODO: support multiple emails
    i.email = json['emails'].first['value'] rescue nil

    i.save!
  end

  # Get a specific User by guid
  # This isn't actually in the spec, but should probably return the same JSON
  # aas create User.
  get '/:id' do
    raise Aok::Errors::NotImplemented
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
