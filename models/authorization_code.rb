class AuthorizationCode < ActiveRecord::Base
  include Oauth2Token

  def access_token(scopes)
    @access_token ||= expired! && identity.access_tokens.create(:client => client, :scopes => scopes, :identity => identity)
  end

  def setup
    super
    self.token = SecureToken.generate
  end

end
