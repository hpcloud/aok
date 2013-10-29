class AddScopesToRefreshTokens < ActiveRecord::Migration
  def self.up
    add_column :refresh_tokens, :scopes, :string
  end

  def self.down
    remove_column :refresh_tokens, :scopes
  end
end
