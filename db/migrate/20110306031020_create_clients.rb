class CreateClients < ActiveRecord::Migration
  def self.up
    create_table :clients do |t|
      t.belongs_to :identity
      t.string :identifier, 
               :secret, 
               :name, 
               :website, 
               :redirect_uri, 
               :scope, 
               :authorized_grant_types,
               :authorities
      t.timestamps
    end
  end

  def self.down
    drop_table :clients
  end
end
