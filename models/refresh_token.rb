class RefreshToken < ActiveRecord::Base
  include Oauth2Token
  self.default_lifetime = 2.weeks
  has_many :access_tokens

  def scopes
    s = read_attribute(:scopes)
    s.nil? ? [] : s.split(',')
  end

  def scopes=(arr)
    val = arr.nil? ? nil : arr.join(',')
    write_attribute(:scopes, val)
  end

  private
  def setup
    super
    self.token = SecureToken.generate
  end
end
