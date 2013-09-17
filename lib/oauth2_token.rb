module Oauth2Token
  def self.included(klass)
    klass.class_eval do
      cattr_accessor :default_lifetime
      self.default_lifetime = 1.minute

      belongs_to :identity
      belongs_to :client

      validates :client, :expires_at, :presence => true
      validates :token, :presence => true, :uniqueness => true

      scope :valid, lambda {
        where(['expires_at >= ?', Time.now.utc])
      }
    end
  end

  def expires_in
    (expires_at - Time.now.utc).to_i
  end

  def expired!
    self.expires_at = Time.now.utc
    self.save!
  end

  def initialize *args
    super *args
    setup
  end

  private

  def setup
    self.expires_at ||= self.default_lifetime.from_now
  end
end