class RenameClientsSecretToSecretDigest < ActiveRecord::Migration
  def self.up
    rename_column :clients, :secret, :secret_digest
  end

  def self.down
    rename_column :clients, :secret_digest, :secret
  end
end
