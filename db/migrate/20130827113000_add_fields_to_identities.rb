class AddFieldsToIdentities < ActiveRecord::Migration
  def self.up
    [ :given_name, :family_name, :phone_number].each do |col|
      add_column :identities, col, :string
    end
    add_column :identities, :username, :citext, :unique => true
    execute "UPDATE identities SET username=email;"
    change_column :identities, :username, :citext, :unique => true, :null => false
    remove_index :identities, :email
    add_column :identities, :guid, :string, :unique => true, :null => false
  end
end
