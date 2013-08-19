if ENV['NO_KATO']
  require 'active_support'
  AppConfig = YAML.load_file('config/aok.yml').with_indifferent_access
else
  require "kato/config"
  begin
    AppConfig = Kato::Config.get("aok").symbolize_keys
    CCConfig = Kato::Config.get("cloud_controller").symbolize_keys
  rescue => ex
    $stderr.puts %[FATAL: Exception encountered while loading config: #{ex}\n#{ex.backtrace.join("\n")}]
    exit 1
  end
end

unless AppConfig
  $stderr.puts %[FATAL: Unable to load config]
  exit 1
end

