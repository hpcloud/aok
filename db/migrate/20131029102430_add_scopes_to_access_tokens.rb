class AddScopesToAccessTokens < ActiveRecord::Migration
  def self.up
    add_column :access_tokens, :scopes, :string
  end

  def self.down
    remove_column :access_tokens, :scopes
  end
end
