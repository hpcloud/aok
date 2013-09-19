class Client < ActiveRecord::Base

  #TODO: Client secrets should be hashed in the DB

  include Aok::ModelAuthoritiesMethods
  has_many :access_tokens
  has_many :refresh_tokens
  belongs_to :identity

  before_validation :setup, :on => :create
  validates :name, :secret, :presence => true #:website, :redirect_uri, :identity,
  validates :identifier, :presence => true, :uniqueness => true

  def scope_list
    parse_list scope
  end

  def authorized_grant_types_list
    parse_list authorized_grant_types
  end

  def valid_grant_type? type
    authorized_grant_types_list.include? type.to_s
  end

  private

  def setup
    self.identifier ||= SecureToken.generate(16)
    self.secret ||= SecureToken.generate
  end

end

