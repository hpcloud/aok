class CreateAccessTokens < ActiveRecord::Migration
  def self.up
    create_table :access_tokens do |t|
      t.belongs_to :identity, :client, :refresh_token
      t.string :token, :limit => 1024, :null => false
      t.datetime :expires_at
      t.timestamps
    end
  end

  def self.down
    drop_table :access_tokens
  end
end
