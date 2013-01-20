begin
  Kato::Doozer.client_name ||= "ehok"
  DoozerTree, DoozerTreeRev = Kato::Doozer.walk("/**", { :symbolize_keys => true })
  if DoozerTree
    AppConfig = DoozerTree[:proc][:ehok][:config]
  end
rescue => ex
  $stderr.puts %[FATAL: Exception encountered while loading config: #{ex}\n#{ex.backtrace.join("\n")}]
  exit 1
end

unless AppConfig
  $stderr.puts %[FATAL: Unable to load config]
  exit 1
end

