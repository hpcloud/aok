class AddRevokedToRefreshTokens < ActiveRecord::Migration
  def self.up
    add_column :refresh_tokens, :revoked, :boolean, :default => false
  end

  def self.down
    remove_column :refresh_tokens, :revoked
  end
end
