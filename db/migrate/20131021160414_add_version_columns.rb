class AddVersionColumns < ActiveRecord::Migration
  def self.up
    add_column :identities, :version, :integer, :default => 0, :null => false
    add_column :groups, :version, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :identities, :version
    remove_column :groups, :version
  end
end
