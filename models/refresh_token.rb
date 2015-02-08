class RefreshToken < ActiveRecord::Base
  include Oauth2Token
  include Aok::ScopesShoehorn
  self.default_lifetime = 2.weeks
  has_many :access_tokens

  # Automatically load the active field from oauth2_token on find.
  after_find do
    init_active
  end

  private
  def setup
    super
    self.token = SecureToken.generate
  end
end
