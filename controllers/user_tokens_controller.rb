class UserTokensController < ApplicationController

  # List Tokens for User
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#list-tokens-for-user-get-oauthusersusernametokens
  get ':username/tokens' do
    raise Aok::Errors::NotImplemented
  end

  # Revoke Token by User
  # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#revoke-token-by-user-delete-oauthusersusernametokensjti
  delete ':username/tokens/:jti' do
    raise Aok::Errors::NotImplemented
  end

end