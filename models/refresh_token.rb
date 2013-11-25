class RefreshToken < ActiveRecord::Base
  include Oauth2Token
  include Aok::ScopesShoehorn
  self.default_lifetime = 2.weeks
  has_many :access_tokens

  private
  def setup
    super
    self.token = SecureToken.generate
  end
end
