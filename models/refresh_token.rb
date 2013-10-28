class RefreshToken < ActiveRecord::Base
  include Oauth2Token
  self.default_lifetime = 1.month
  has_many :access_tokens

  private
  def setup
    super
    self.token = SecureToken.generate
  end
end
