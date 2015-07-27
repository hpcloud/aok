class UsersController < ApplicationController
  helpers UserHelper

  # Create a User
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#create-a-user-post-users
  # http://www.simplecloud.info/specs/draft-scim-core-schema-01.html#user-resource
  post '/?' do
    user_details = CreateUserMessage.decode request.body.read
    user = Identity.new
    set_user_details user, user_details, :allow_password
    if user.save
      return 201, scim_user_response(user)
    else
      handle_save_error user
    end

  end

  # Get a specific User by guid
  get '/:id' do
    guid = params[:id]
    user = Identity.
      where(guid: guid).
      includes(:groups =>[:parent_groups]).
      limit(1).first
    raise Aok::Errors::ScimNotFound.new("User #{guid} does not exist") unless user
    scim_user_response user
  end

  # Update a User
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#update-a-user-put-usersid
  put '/:id' do
    user_details = UpdateUserMessage.decode request.body.read
    user = Identity.find_by_guid params[:id]
    raise Aok::Errors::ScimNotFound.new("User #{params[:id]} does not exist") unless user
    set_user_details user, user_details
    if user.save
      return scim_user_response(user)
    else
      handle_save_error user
    end
  end

  # Change Password
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#change-password-put-usersidpassword
  put '/:id/password' do
    unless AppConfig[:strategy][:use].to_s == 'builtin'
      raise Aok::Errors::NotImplemented.new("Password change not supported with current authentication strategy.")
    end

    password_details = read_json_body
    user = Identity.find_by_guid params[:id]
    raise Aok::Errors::ScimNotFound.new("User #{params[:id]} does not exist") unless user

    # user changing own password should require oldPassword,
    # admin changing passwords should not.
    if user == security_context.principal
      if !user.authenticate(password_details['oldPassword'])
        logger.debug "user did not provide correct oldPassword"
        raise Aok::Errors::AokError.new 'unauthorized', 'oldPassword is incorrect', 400
      end
    elsif security_context.identity && !(security_context.token.has_scope?('uaa.admin') || security_context.token.has_scope?('cloud_controller.admin'))
      # bug 101940: AOK loosening restrictions to allow cloud_controller.admin to change
      # user's passwords (in addition to allowing uaa.admin to do it).
      #
      # XXX: aocole believes this behavior is wrong-- client should still need uaa.admin scope
      # this behavior is here to replicate uaa's behavior, but contradicts docs at:
      # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-Security.md#password-change
      logger.debug "User #{security_context.identity.inspect} trying to change password for #{user.inspect} but does not have needed admin scope. Scopes were #{security_context.token.scopes.inspect}."
      raise Aok::Errors::AccessDenied.new(
        "You are not permitted to access this resource."
      )
    end

    user.password = user.password_confirmation = password_details['password']
    if user.save
      return scim_user_response(user)
    else
      handle_save_error user
    end
  end

  # Query for information
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#query-for-information-get-users
  # http://www.simplecloud.info/specs/draft-scim-api-01.html#query-resources
  # http://tools.ietf.org/html/draft-ietf-scim-core-schema-02#section-12
  # TODO: support sortBy query param
  get '/?' do
    begin
      filter = if !params[:filter].blank?
        Aok::Scim::ActiveRecordQueryBuilder.new.build_query(params[:filter])
      else
        true
      end
    rescue
      # This error doesn't show up in logs
      raise Aok::Errors::ScimFilterError.new($!.message)
    end
    users = query_users_as_scim(filter, params)

    users.to_json
  end

  # Delete a User
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#delete-a-user-delete-usersid
  delete '/:id' do
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

    # Also prunes nil values
    def self.downcase_keys! obj
      case obj
      when Hash
        keys = obj.keys.dup
        keys.each do |k|
          value = downcase_keys!(obj.delete(k))
          obj[k.downcase] = value unless value.nil?
        end
      when Array
        obj.collect!{|o| downcase_keys!(o)}
      end
      obj
    end

    optional :id, String
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

    optional :phonenumbers do
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
