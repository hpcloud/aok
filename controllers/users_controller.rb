class UsersController < ApplicationController

        # XXX Test only methods:
        # Reset -- delete all users
        get '/RESET/' do
          Identity.delete_all
          return
        end
        # TODO Move these to test-only class.

  # Create a User
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#create-a-user-post-users
  # http://www.simplecloud.info/specs/draft-scim-core-schema-01.html#user-resource
  post '/?' do
    # authenticate! #TODO enforce permissions on this call
    # TODO: Authentication, Validation, robustification
    user_details = CreateUserMessage.decode request.body.read
    user = Identity.new
    set_user_details user, user_details, :allow_password
    if user.save
      user = Identity.find(user.id) #reload version
      return 201, scim_user_response(user)
    else
      handle_save_error user
    end

  end

  # Get a specific User by guid
  # This isn't actually in the spec, but should probably return the same JSON
  # aas create User.
  get '/:id' do
    # authenticate! #TODO enforce permissions on this call
    id = params[:id]
    user = Identity.find_by_guid(id)
    raise Aok::Errors::ScimNotFound.new("User #{params[:id]} does not exist") unless user
    scim_user_response user
  end

  # Update a User
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#update-a-user-put-usersid
  put '/:id' do
    authenticate! #TODO enforce permissions on this call
    user_details = UpdateUserMessage.decode request.body.read
    user = Identity.find_by_guid params[:id]
    raise Aok::Errors::ScimNotFound.new("User #{params[:id]} does not exist") unless user
    set_user_details user, user_details
    if user.save
      user = Identity.find(user.id) #reload version
      return scim_user_response(user)
    else
      handle_save_error user
    end
  end

  # Change Password
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#change-password-put-usersidpassword
  put '/:id/password' do
    authenticate! #TODO enforce permissions on this call
    password_details = read_json_body
    user = Identity.find_by_guid params[:id]
    raise Aok::Errors::ScimNotFound.new("User #{params[:id]} does not exist") unless user

    # TODO: user changing own password should require oldPassword,
    # admin changing passwords should not.
    # if !user.authenticate(password_details['oldPassword'])
    #   raise Aok::Errors::AokError.new 'unauthorized', 'oldPassword is incorrect', 401
    # end

    user.password = user.password_confirmation = password_details['password']
    if user.save
      user = Identity.find(user.id) #reload version
      return scim_user_response(user)
    else
      handle_save_error user
    end
  end

  # Query for information
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#query-for-information-get-users
  # http://www.simplecloud.info/specs/draft-scim-api-01.html#query-resources
  # http://tools.ietf.org/html/draft-ietf-scim-core-schema-02#section-12
  # TODO: authentication
  # TODO: support attributes query param
  # TODO: support sortBy query param
  # TODO: support startIndex query param
  # TODO: support count query param
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
      resources.push(user_hash(identity))
    end

    return {
      'schemas' => ["urn:scim:schemas:core:1.0"],
      'resources' => resources,
      'totalResults' => resources.size
    }.to_json

  end

  # Delete a User
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#delete-a-user-delete-usersid
  delete '/:id' do
    # authenticate! #TODO enforce permissions on this call
    id = params[:id]
    user = Identity.find_by_guid(id)
    raise Aok::Errors::ScimNotFound.new("User #{id} does not exist") \
      unless user
    user.destroy
    return 200
  end

  def set_user_details user, user_details, allow_password=false
    if user_details.name
      user.family_name = user_details.name['familyname']
      user.given_name = user_details.name['givenname']
    end
    user.username = user_details.username
    user.password =
      user.password_confirmation =
      user_details.password if allow_password

    # TODO: support multiple emails
    if user_details.emails && user_details.emails.first
      user.email = user_details.emails.first['value']
    end
    return user
  end

  def user_hash user
    user_data = {
      'schemas' => ['urn:scim:schemas:core:1.0'],
      'externalId' => user.username,
      'id' => user.guid,
      'meta' => {
        'version' => user.version,
        'created' => user.created_at.utc.strftime(UAA_DATE_FORMAT),
        'lastModified' => user.updated_at.utc.strftime(UAA_DATE_FORMAT),
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
    user_data["emails"] = [
      {"value" => user.email}
    ]
    user_data['groups'] = user.groups.collect do |group|
      {
        'display' => group.name,
        'value' => group.guid
      }
    end
    return user_data
  end

  def scim_user_response user
    h = user_hash(user)
    headers['ETag'] = %Q{"#{user.version}"}
    h.to_json
  end

  def user_xrds
    types = [
             OpenID::OPENID_2_0_TYPE,
             OpenID::OPENID_1_0_TYPE,
             OpenID::SREG_URI,
            ]

    render_xrds(types)
  end


  def handle_save_error user
    error = 'invalid_scim_resource'
    status 400
    if (user.errors[:username] && user.errors[:username].any?{|e|e =~ /taken/})
      status 409
      error = 'scim_resource_already_exists'
    end
    return  {
      :error => error,
      :error_description => user.errors.full_messages.join('. ')
    }.to_json
  end

  class CreateUserMessage < JsonMessage

    def self.logger
      ApplicationController.logger
    end

    def self.decode json
      #logger.debug "JSON to decode: #{json.inspect}"
      begin
        dec_json = Yajl::Parser.parse(json)
      rescue => e
        raise ParseError, e.to_s
      end
      downcase_keys!(dec_json)
      #logger.debug "Downcased json: #{dec_json.inspect}"
      from_decoded_json(dec_json)
    end

    def self.downcase_keys! obj
      case obj
      when Hash
        keys = obj.keys.dup
        keys.each do |k|
          obj[k.downcase] = downcase_keys!(obj.delete(k))
        end
      when Array
        obj.collect!{|o| downcase_keys!(o)}
      end
      obj
    end

    optional :id, String # TODO: needed to pass integration tests, but do we want it?
    optional :externalid, String
    required :username, String
    optional :password, String
    optional :usertype, String
    optional :meta do dict(String, Object) end
    optional :name do
      {
        optional('givenname')  => String,
        optional('familyname') => String,
        optional('formatted')  => String,
      }
    end

    optional :emails do
      [
        {'value' => String}
      ]
    end

    optional :active do bool end

    optional :schemas, [String]
    optional :groups, [Object]

  end

  UpdateUserMessage = CreateUserMessage

end
