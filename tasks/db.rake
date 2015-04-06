namespace :db do
  desc "Migrate the database to the current version"
  task :migrate => :config do
    ActiveRecord::Base.establish_connection(Aok::Config.get_database_config)
    ActiveRecord::Migrator.migrate 'db/migrate'
  end

  desc "Create the database"
  task :create => :config do
    options = {:charset => 'utf8', :collation => 'utf8_unicode_ci'}
    @db_config = Aok::Config.get_database_config
    ActiveRecord::Base.establish_connection @db_config.merge(:database => nil)
    ActiveRecord::Base.connection.create_database @db_config[:database], options
  end

  desc "Start an interactive database session"
  task :console => :config do
    config = Aok::Config.get_database_config
    ENV["PGPASSWORD"] = config[:password]
    exec("psql -w -h #{config[:host]} #{config[:database]} #{config[:username]}")
  end

  desc "Delete the database"
  task :drop => :config do
    config = Aok::Config.get_database_config.dup
    db_name = config[:database]
    config[:database] = nil
    ActiveRecord::Base.establish_connection config
    ActiveRecord::Base.connection.drop_database(db_name)
  end

  desc "Delete and recreate the database"
  task :recreate => [:drop, :create, :migrate] do
  end

  namespace :migration do
    desc "Create a migration"
    task :create, :name do |t, args|
      require 'active_support'
      require 'active_support/core_ext/string/inflections'
      File.open("./db/migrate/#{Time.now.strftime("%Y%m%d%H%M%S")}_#{args[:name].underscore}.rb", 'w+') do |f|
        f.write <<-EOS.gsub(/^ {10}/,'')
          class #{args[:name].camelize} < ActiveRecord::Migration
            def self.up

            end

            def self.down

            end
          end
        EOS
      end
    end
  end
end