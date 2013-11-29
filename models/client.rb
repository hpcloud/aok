class Client < ActiveRecord::Base

  #TODO: Client secrets should be hashed in the DB

  include Aok::ModelAuthoritiesMethods
  has_many :access_tokens
  has_many :refresh_tokens
  belongs_to :identity

  before_validation :setup, :on => :create
  validates :name, :presence => true #:website, :redirect_uri, :identity,
  validates :identifier, :presence => true, :uniqueness => true

  validates :secret, :presence => true,
    :if => Proc.new{|c|c.valid_grant_type?('client_credentials')}

  before_validation do
    if (valid_grant_type?('authorization_code') || valid_grant_type?('password')) &&
      !valid_grant_type?('refresh_token')
      add_grant_type 'refresh_token'
    end
  end
  validate :grant_type_restrictions
  def grant_type_restrictions
    if (authorized_grant_types_list & %w{implicit authorization_code}).size == 2
      errors.add(:authorized_grant_types,
        "can't include both 'implicit' and 'authorization_code'")
    end
  end

  def scope_list
    parse_list scope
  end

  def authorized_grant_types_list
    parse_list authorized_grant_types
  end

  def valid_grant_type? type
    authorized_grant_types_list.include? type.to_s
  end

  def authorities_list
    parse_list authorities
  end

  def has_authority?(authority)
    authorities_list.include?(authority)
  end

  def add_grant_type type
    self.authorized_grant_types = (authorized_grant_types_list << type).uniq.join(',')
  end

  # TODO: Store in the database
  def refresh_token_validity; return 120; end
  def access_token_validity; return 60; end

  private

  def setup
    self.identifier ||= SecureToken.generate(16)
  end

end

