require 'active_support/core_ext/hash/deep_merge'
begin
  Kato::Doozer.client_name ||= "aok"
  AppConfig = Kato::Doozer.walk("/proc/aok/config/**", { :symbolize_keys => true }).first

  CCConfig = Kato::Doozer.walk("/proc/cloud_controller/config/**", { :symbolize_keys => true }).first

  db_config = CCConfig[:database_environment].deep_merge(AppConfig[:database_environment])

rescue => ex
  $stderr.puts %[FATAL: Exception encountered while loading config: #{ex}\n#{ex.backtrace.join("\n")}]
  exit 1
end

unless AppConfig
  $stderr.puts %[FATAL: Unable to load config]
  exit 1
end

