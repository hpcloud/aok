class MakeIdentitiesCaseInsensitive < ActiveRecord::Migration
  def self.up
    execute 'CREATE EXTENSION citext;'
    change_column :identities, :email, :citext, :null => false
  end
end
