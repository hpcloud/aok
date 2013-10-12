class CreateGroups < ActiveRecord::Migration
  def self.up
    create_table :groups do |t|
      t.string :name, :guid, :null => false
      t.timestamps
    end

    create_table :groups_identities, :id => false do |t|
      t.integer :group_id, :identity_id, :null => false
    end
  end

  def self.down
    drop_table :groups
    drop_join_table :groups, :identities
  end
end
