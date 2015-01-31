class AddRevokedToAccessTokens < ActiveRecord::Migration
  def self.up
    add_column :access_tokens, :revoked, :boolean, :default => false
  end

  def self.down
    remove_column :access_tokens, :revoked
  end
end
