require "kato/config"
begin
  AppConfig = Kato::Config.get("aok").symbolize_keys
  CCConfig = Kato::Config.get("cloud_controller_ng").symbolize_keys
rescue => ex
  $stderr.puts %[FATAL: Exception encountered while loading config: #{ex}\n#{ex.backtrace.join("\n")}]
  exit 1
end

unless AppConfig
  $stderr.puts %[FATAL: Unable to load config]
  exit 1
end

