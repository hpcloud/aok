require 'securerandom'
module SecureToken
  def self.generate(bytes = 64)
    SecureRandom.urlsafe_base64(bytes)
  end
end