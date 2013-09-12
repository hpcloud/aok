require "kato/config"
begin
  AppConfig = Kato::Config.get("aok").symbolize_keys
  CCConfig = Kato::Config.get("cloud_controller_ng").symbolize_keys

  AppConfig[:commit_id] = File.read(File.dirname(__FILE__) + '/../.pkg-gitdescribe').strip
rescue => ex
  $stderr.puts %[FATAL: Exception encountered while loading config: #{ex}\n#{ex.backtrace.join("\n")}]
  exit 1
end

unless AppConfig
  $stderr.puts %[FATAL: Unable to load config]
  exit 1
end
