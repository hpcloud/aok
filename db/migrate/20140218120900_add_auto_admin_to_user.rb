class AddAutoAdminToUser < ActiveRecord::Migration
  def self.up
    add_column :identities, :auto_admin, :boolean, :default => false
  end

  def self.down
    remove_column :identities, :auto_admin
  end
end