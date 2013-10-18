# This model represents SCIM groups. These groups show up as the list of
# authorities that an Identity has, and in turn affects what scopes they
# may be granted on oauth2 tokens.
class Group < ActiveRecord::Base
  default_scope  { select('*, groups.xmin') }
  has_and_belongs_to_many :identities
  has_and_belongs_to_many :groups,
    :foreign_key => "group_a_id",
    :association_foreign_key => "group_b_id",
    :before_add => :no_circular_groups
  has_and_belongs_to_many :parent_groups,
    :join_table => "groups_groups",
    :class_name => "Group",
    :foreign_key => "group_b_id",
    :association_foreign_key => "group_a_id"
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

  def no_circular_groups(gs, seen={})
    if gs.kind_of? Group
      seen[guid] = true
      seen[gs.guid] = true
      gs = gs.groups
    end
    gs.uniq!
    gs.each do |g|
      if seen[g.guid]
        raise ActiveRecord::RecordInvalid.new(
          "Groups can't have circular references. Group #{g.guid} already seen.")
        break
      end
      seen[g.guid] = true
      no_circular_groups(g.groups, seen)
    end
  end

  def version
    raise "Version will only be accurate on persisted objects." if changed?
    xmin.to_i
  end

end
