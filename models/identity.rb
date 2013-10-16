class Identity < OmniAuth::Identity::Models::ActiveRecord
  include Aok::ModelAuthoritiesMethods
  has_many :protected_resources
  has_many :access_tokens
  has_many :authorization_codes
  has_many :clients
  has_and_belongs_to_many :groups

  alias_attribute :first_name, :given_name
  alias_attribute :last_name, :family_name

  validates :username,
    :uniqueness => { :case_sensitive => false },
    :length => { :maximum => 255 }

  validates :guid,
    :uniqueness => { :case_sensitive => true },
    :length => { :maximum => 255 },
    :presence => true

  validates :email, :presence => true

  before_create do
    if self.groups.empty?
      groups = Group.find_all_by_name AppConfig[:oauth][:users][:default_authorities]
      self.groups = groups
    end
  end

  before_validation do
    self.email = email.strip.downcase if attribute_present?("email")
    self.username = username.strip if attribute_present?("username")
    self.guid ||= SecureRandom.uuid

    # TODO: Under some circumstances, password is not a required attribute of
    # an Identity. How should we validate that a password is present when we need one?
    if !self.password_digest
      self.password = self.password_confirmation = SecureRandom.urlsafe_base64(64)
    end
  end

  auth_key 'username'

  # Used by Omniauth
  def uid
    guid ? guid.to_s : nil
  end

  def version
    raise "Version will only be accurate on persisted objects." if changed?
    Identity.where(id: id).select(:xmin).first.xmin.to_i
  end

  def email=(val)
    write_attribute :email, val.strip.downcase
  end

  def authorities_list
    groups.collect(&:name).uniq
  end

  def authorities_list_with_defaults
    (authorities_list | AppConfig[:oauth][:users][:default_authorities])
  end

end
