class CreateIdentities < ActiveRecord::Migration
  def self.up
    execute "delete from users where crypted_password is null"

    rename_table :users, :identities

    execute "ALTER TABLE identities ALTER COLUMN id SET DEFAULT nextval('public.identities_id_seq'::regclass)"
    execute "ALTER INDEX users_pkey RENAME TO identities_pkey"

    rename_column :identities, :crypted_password, :password_digest
    change_column :identities, :password_digest, :string, :null => false
    add_index :identities, :email, :unique => true
  end

  def self.down
    # why would you want to go back?
    raise ActiveRecord::IrreversibleMigration
  end
end
