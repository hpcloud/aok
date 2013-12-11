class AddUniqueIndexOnGroupMembers < ActiveRecord::Migration
  def self.up
    # first delete any existing dupes
    execute("
      DELETE FROM groups_identities a
      WHERE a.ctid <> (
        SELECT min(b.ctid)
        FROM   groups_identities b
        WHERE  a.group_id = b.group_id AND a.identity_id = b.identity_id
      );
    ")
    execute("
      DELETE FROM groups_groups a
      WHERE a.ctid <> (
        SELECT min(b.ctid)
        FROM   groups_groups b
        WHERE  a.group_a_id = b.group_a_id AND a.group_b_id = b.group_b_id
      );
    ")
    # add indices to prevent future dupes
    add_index :groups_identities, [:group_id, :identity_id], :unique => true
    add_index :groups_groups, [:group_a_id, :group_b_id], :unique => true
  end

  def self.down
    remove_index :groups_identities, [:group_id, :identity_id]
    remove_index :groups_groups, [:group_a_id, :group_b_id]
  end
end
