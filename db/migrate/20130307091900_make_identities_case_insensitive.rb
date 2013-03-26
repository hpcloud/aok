class MakeIdentitiesCaseInsensitive < ActiveRecord::Migration
  def self.up
    dupes = execute('select lower(email) as te, count(lower(email)) as num from identities group by te having COUNT(lower(email)) > 1').field_values('te')
    if dupes.size > 0
      raise "Duplicate users found in the database while changing to\n"+
      "case-insensitive index. Please de-dupe the following records:\n"+
      dupes.join("\n")
    end

    execute 'CREATE EXTENSION citext;'
    change_column :identities, :email, :citext, :null => false
  end
end
