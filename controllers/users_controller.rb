class UsersController < ApplicationController

  # Create a User
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#create-a-user-post-users
  post '/?' do
    raise Aok::Errors::NotImplemented
  end

  # Update a User
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#update-a-user-put-usersid
  put '/:id' do
    raise Aok::Errors::NotImplemented
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
  # apidock.com/rails/ActiveRecord/Base
  get '/?' do
    # params
    response = {
      'schemas' => ["urn:scim:schemas:core:1.0"],
      'totalResults' => 0,
      'Resources' => [],
    }
    Identity.all.each do |user|
      response['Resources'].push({
        'id' => user.guid,
        'userName' => user.username,
      })
    end
    response['totalResults'] = response['Resources'].size

    return response.to_json
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
