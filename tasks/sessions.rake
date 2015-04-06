desc "Clear expired sessions from the database"
task :reap_sessions => :config do
  ActiveRecord::Base.establish_connection(Aok::Config.get_database_config)
  deleted = Session.delete(Session.where(["created_at < ?", Time.now - 1.day]))
  puts "Reaped #{deleted} sessions"
end