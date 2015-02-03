module Oauth2Token
  # Non database attribute to show if this token is still active
  # Note: init_active needs to be called for this to be set (automatically done on finds of access|refresh_tokens)
  attr_accessor :active

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

  def revoke!
    self.revoked = true
    self.save!
  end

  # Initializes the non-persisted :active attribute
  def init_active
    active = true
    if self.revoked
      active = false
    elsif self.expires_in <= 0
      active = false
    end

    self.active = active
  end

  def initialize *args
    super *args
    setup
  end

  private

  def setup
    self.expires_at ||= self.default_lifetime.from_now.utc
  end
end