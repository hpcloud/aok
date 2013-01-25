class CreateSessions < ActiveRecord::Migration
  def self.up
    create_table :sessions do |t|
      t.string :sid, :null => false
      t.string :data, :limit => 20 * 1024
      t.timestamps
    end
    add_index :sessions, :sid, :unique => true
  end

  def self.down
    drop_table :sessions
  end
end
