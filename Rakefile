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
end

desc "Clear expired sessions from the database"
task :reap_sessions => :config do
  ActiveRecord::Base.establish_connection(Aok::Config.get_database_config)
  deleted = Session.delete(Session.where(["created_at < ?", Time.now - 1.day]))
  puts "Reaped #{deleted} sessions"
end

desc "Reload AOK's configuration from the YAML config file, overwriting current config."
task :load_config do
  require 'kato/config'
  require 'yaml'
  config_file = File.join(File.dirname(__FILE__), 'config', 'aok.yml')
  config = YAML.load_file(config_file)
  Kato::Config.set("aok", "/", config)
end

task :config do
  require 'active_record'
  require_relative "config/config"
  require_relative 'models/session'
  puts "Using #{ENV['RACK_ENV'].inspect} environment"
end

desc "Import users and passwords from the cloud controller. This is for migrating to AOK
from the old ( <=2.8 ) Stackato login system to AOK. This will drop and recreate AOK's
database. This is only necessary if you want to use AOK but still use a built-in password
database. This is not necessary if you want to use AOK with an external auth system such
as LDAP."
task :import_users_from_cloud_controller => :config do
  require 'kato/ui'
  require 'kato/config'
  unless ENV['FORCE'] == 'true'
    puts <<-END.gsub(/^[ ]+/, '')
      ****************************************************************************
      * WARNING! You are about to import users and their passwords from the Cloud
      * Controller in to AOK. This will DROP AND RECREATE your AOK database.
      *
      * If you know what you are doing you can run this task with FORCE=true to
      * prevent this message appearing.
      ****************************************************************************

      Are you sure? (Yes|No) [No]
    END
    confirmation = STDIN.gets.chomp.downcase
    unless confirmation == 'yes'
      puts('Exiting')
      exit
    end
  end
  users = []
  Kato::UI.action "Migrating user accounts" do
    cc_config = Kato::Config.get('cloud_controller')
    ActiveRecord::Base.establish_connection(cc_config['database_environment']['production'])
    begin
      unless ActiveRecord::Base.connection.column_exists?(:users, :crypted_password)
        puts "Couldn't find the necessary fields in the Cloud Controller DB. Maybe already migrated?"
        exit
      end

      rows = ActiveRecord::Base.connection.execute("select email, crypted_password from users where crypted_password is not null")
      users = []
      rows.each{|row| users << row}
      ActiveRecord::Base.connection.disconnect!
      if users.empty?
        puts "Couldn't find any users with passwords in the Cloud Controller database. Doing nothing."
        exit
      end

      Rake::Task["db:drop"].invoke
      Rake::Task["db:create"].invoke
      Rake::Task["db:migrate"].invoke

      Aok::Config.initialize_database
      values = users.collect do |user|
        "(" +
        %w{email crypted_password}.collect do |column|
          ActiveRecord::Base.connection.quote user[column]
        end.join(', ') +
        ")"
      end.join(', ')
      ActiveRecord::Base.connection.execute("insert into identities (email, password_digest) values #{values}")
      puts "Imported #{users.size} user(s). Only users with passwords were imported."
    ensure
      ActiveRecord::Base.connection.disconnect!
    end
  end

end

desc "Export passwords to the cloud controller. This is for switching BACK to the
cloud controller's built-in password login system after using AOK with the 'builtin'
strategy."
task :export_passwords_to_cloud_controller => :config do
  require 'kato/config'

  puts "Gathering passwords from AOK..."
  users = []
  Aok::Config.initialize_database
  rows = ActiveRecord::Base.connection.execute("select email, password_digest from identities")
  ActiveRecord::Base.connection.disconnect!
  users = []
  rows.each{|row| users << row}
  if users.empty?
    puts "Couldn't find any users to migrate. Doing nothing."
    exit
  end

  num_migrated = 0
  cc_config = Kato::Config.get('cloud_controller')
  ActiveRecord::Base.establish_connection(cc_config['database_environment']['production'])
  ActiveRecord::Base.transaction do
    users.each do |user|
      num_migrated += ActiveRecord::Base.connection.update_sql("
        update users
        set crypted_password = #{ActiveRecord::Base.connection.quote(user['password_digest'])}
        where email = #{ActiveRecord::Base.connection.quote(user['email'])}")
    end
  end
  if num_migrated.zero?
    puts "Passwords were already in sync."
    exit
  end
  puts "Some passwords were already synced." if users.size != num_migrated
  puts "Moved #{num_migrated} of #{users.size} password(s) to the cloud_controller."
end

# require 'rspec/core/rake_task'
# desc "run specs"
# RSpec::Core::RakeTask.new

namespace :test do
  task :integration do
    Dir.chdir '../uaa'
    `rm -rf uaa/target/surefire-reports`
    require 'pty'
    cmd = "mvn test -P aok --projects uaa"
    begin
      ENV['VCAP_BVT_TARGET']='stackato-andrew.local'
      PTY.spawn( cmd ) do |stdin, stdout, pid|
        begin
          # Do stuff with the output here. Just printing to show it works
          stdin.each { |line| print line }
        rescue Errno::EIO
          puts "Errno:EIO error, but this probably just means " +
                "that the process has finished giving output"
        end
      end
    rescue PTY::ChildExited
      puts "The child process exited!"
    end
  end

  task :results do
    `xdg-open ../uaa/uaa/target/surefire-reports`
  end
end