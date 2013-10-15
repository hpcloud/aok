# This model represents SCIM groups. These groups show up as the list of
# authorities that an Identity has, and in turn affects what scopes they
# may be granted on oauth2 tokens.
class Group < ActiveRecord::Base
  has_and_belongs_to_many :identities

  before_validation do
    self.guid ||= SecureRandom.uuid
  end

  validates :name,
    :uniqueness => { :case_sensitive => false },
    :length => { :maximum => 255 },
    :presence => true

  validates :guid,
    :uniqueness => { :case_sensitive => true },
    :length => { :maximum => 255 },
    :presence => true

end
