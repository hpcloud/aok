begin
  Kato::Doozer.client_name ||= "aok"
  AppConfig = Kato::Doozer.walk("/proc/aok/config/**", { :symbolize_keys => true }).first

  CCConfig = Kato::Doozer.walk("/proc/cloud_controller/config/**", { :symbolize_keys => true }).first

  AppConfig[:database_environment] = CCConfig[:database_environment]
  AppConfig[:database_environment][:production][:database]  = 'aok'
  AppConfig[:database_environment][:development][:database] = 'db/aok.sqlite3'
  AppConfig[:database_environment][:test][:database]        = 'db/aok.test.sqlite3'

rescue => ex
  $stderr.puts %[FATAL: Exception encountered while loading config: #{ex}\n#{ex.backtrace.join("\n")}]
  exit 1
end

unless AppConfig
  $stderr.puts %[FATAL: Unable to load config]
  exit 1
end

