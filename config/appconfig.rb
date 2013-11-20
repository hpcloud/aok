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
  AppConfig = Kato::Config.get("aok").symbolize_keys
  check_config(AppConfig)
  CCConfig = Kato::Config.get("cloud_controller_ng").symbolize_keys

  AppConfig[:commit_id] = File.read(File.dirname(__FILE__) + '/../.pkg-gitdescribe').strip
  AppConfig[:timestamp] = File.mtime(File.dirname(__FILE__) + '/../.pkg-gitdescribe')
rescue => ex
  $stderr.puts %[FATAL: Exception encountered while loading config: #{ex}\n#{ex.backtrace.join("\n")}]
  exit 1
end

unless AppConfig
  $stderr.puts %[FATAL: Unable to load config]
  exit 1
end
