class AddGroupsGroupsJoinTable < ActiveRecord::Migration
  def self.up
    create_table :groups_groups, :id => false do |t|
      t.integer :group_a_id, :group_b_id, :null => false
    end

  end

  def self.down

  end
end
