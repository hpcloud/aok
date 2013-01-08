require "./config/dependencies"

namespace :db do
  task :migrate do
    ActiveRecord::Base.establish_connection(Ehok::Config.get_database_config)
    ActiveRecord::Migrator.migrate 'db/migrate'
  end

  task :create do
    options = {:charset => 'utf8', :collation => 'utf8_unicode_ci'}
    @db_config = Ehok::Config.get_database_config
    ActiveRecord::Base.establish_connection @db_config.merge(:database => nil)
    ActiveRecord::Base.connection.create_database @db_config[:database], options

  end

  task :console do
    config = Ehok::Config.get_database_config
    ENV["PGPASSWORD"] = config[:password]
    exec("psql -w -h #{config[:host]} #{config[:database]} #{config[:username]}")
  end

  task :drop do
    config = Ehok::Config.get_database_config
    ENV["PGPASSWORD"] = config[:password]
    exec("dropdb -w -U #{config[:username]} -h #{config[:host]} #{config[:database]}")
  end
end