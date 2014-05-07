require "kato/config"

def check_config hash
  hash.each do |key, value|
    if key.to_s.include?('-')
      $stderr.puts "WARNING: Config key #{key.inspect} contains a hyphen. AOK-style keys use _ to separate words."
    end
    check_config(value) if value.kind_of?(Hash)
  end
end

begin
  conf = Kato::Config.get("aok").symbolize_keys

  if ENV['RACK_ENV'] == 'test'
    require 'active_support/core_ext/hash/deep_merge'
    $test_config ||= {}
    conf.deep_merge!($test_config)
  end
  AppConfig = conf

  check_config(AppConfig)
  CCConfig = Kato::Config.get("cloud_controller_ng").symbolize_keys
rescue => ex
  $stderr.puts %[FATAL: Exception encountered while loading config: #{ex}\n#{ex.backtrace.join("\n")}]
  exit 1
end

unless AppConfig
  $stderr.puts %[FATAL: Unable to load config]
  exit 1
end
