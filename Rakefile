namespace :db do
  task :migrate => :database_config do
    ActiveRecord::Base.establish_connection(Ehok::Config.get_database_config)
    ActiveRecord::Migrator.migrate 'db/migrate'
  end

  task :create => :database_config do
    options = {:charset => 'utf8', :collation => 'utf8_unicode_ci'}
    @db_config = Ehok::Config.get_database_config
    ActiveRecord::Base.establish_connection @db_config.merge(:database => nil)
    ActiveRecord::Base.connection.create_database @db_config[:database], options

  end

  task :console => :database_config do
    config = Ehok::Config.get_database_config
    ENV["PGPASSWORD"] = config[:password]
    exec("psql -w -h #{config[:host]} #{config[:database]} #{config[:username]}")
  end

  task :drop => :database_config do
    config = Ehok::Config.get_database_config
    ENV["PGPASSWORD"] = config[:password]
    exec("dropdb -w -U #{config[:username]} -h #{config[:host]} #{config[:database]}")
  end
end

task :load_config do
  require 'kato/doozer'
  require 'yaml'
  config_file = File.join(File.dirname(__FILE__), 'config', 'ehok.yml')
  config = YAML.load_file(config_file)
  Kato::Doozer.set_component_config("ehok", config)
end

task :database_config do 
  require 'active_record'
  require "./config/database"
end