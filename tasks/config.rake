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
  require_relative "../config/config"
  require_relative '../models/session'
  puts "Using #{ENV['RACK_ENV'].inspect} environment"
end
