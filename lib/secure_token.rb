require 'securerandom'
module SecureToken
  def self.generate(bytes = 64)
    SecureRandom.base64(bytes)
  end
end