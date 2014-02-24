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

require 'rspec/core/rake_task'
desc "run specs"
RSpec::Core::RakeTask.new

namespace :test do
  desc "Run the java integration tests from the UAA project."
  task :integration => :truststore do
    Dir.chdir '../uaa'
    `rm -rf uaa/target/surefire-reports`
    require 'pty'
    cmd = "mvn test -P aok --projects uaa"
    begin
      ENV['VCAP_BVT_TARGET']="#{ENV["VMNAME"]}.local"
      PTY.spawn( cmd ) do |stdin, stdout, pid|
        begin
          # Do stuff with the output here. Just printing to show it works
          stdin.each { |line| print line }
        rescue Errno::EIO
          # puts "Errno:EIO error, but this probably just means " +
          #       "that the process has finished giving output"
        end
      end
    rescue PTY::ChildExited
      puts "The child process exited!"
    end
  end

  # If you change the tests and then run them, you'll still get the old tests
  # because maven downloads the identity-common jar from springsecurity.org
  # for some dumb reason. This builds the jar locally and copies it to the
  # cache location maven expects. I could learn maven and make it do the right
  # thing, but then I would have to learn maven.
  desc "Rebuild the java integration tests."
  task :rebuild do
    Dir.chdir '../uaa/common'
    require 'pty'
    cmd = "mvn package"
    begin
      ENV['VCAP_BVT_TARGET']="#{ENV["VMNAME"]}.local"
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
    require 'fileutils'
    target = "#{ENV['HOME']}/.m2/repository/org/cloudfoundry/identity/cloudfoundry-identity-common/1.4.3/cloudfoundry-identity-common-1.4.3.jar"
    FileUtils.cp 'target/cloudfoundry-identity-common-1.4.3.jar', target
    `sha1sum #{target} > #{target}.sha1`
    puts `ls -ltr #{target}`
  end

  desc "Open a window with the integration test results failures"
  task :results do
    viewer = ENV['DIRVIEWCMD'] || 'sub'
    `which #{viewer}`
    if $? != 0
      puts "Command `#{viewer}` not found. Please set DIRVIEWCMD to a command " +
           "capable of viewing a directory contents."
      abort
    end

    dir = '../uaa/uaa/target/surefire-reports'
    `grep  -L -E "<(failure|error|skipped)" #{dir}/* | xargs rm`
    `#{viewer} -n #{dir}`
  end

  desc "Set up aok's config for testing. Insecure, not for production."
  task :setup => :config do
    require 'kato/config'
    require 'yaml'

    # set up kato config
    config_file = File.join(File.dirname(__FILE__), 'test', 'test_config.yml')
    config = YAML.load_file(config_file)
    old_config = Kato::Config.get("aok", '/')
    unless File.exist?('old_config.yml')
      File.open('old_config.yml', 'w+') {|f| f.puts(old_config.to_yaml)}
    end
    Kato::Config.set("aok", "/", old_config.deep_merge(config))

    # restart kato for config changes to take effect
    require 'pty'
    cmd = "kato restart"
    begin
      PTY.spawn( cmd ) do |stdin, stdout, pid|
        begin
          stdin.each { |line| print line }
        rescue Errno::EIO
          # puts "Errno:EIO error, but this probably just means " +
          #       "that the process has finished giving output"
        end
      end
    rescue PTY::ChildExited
      puts "The child process exited!"
    end
  end

  desc "Set up java truststore for tests"
  task :truststore do
    `yes yes | make truststore`
  end
end
