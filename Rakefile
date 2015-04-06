$LOAD_PATH.unshift(File.dirname(__FILE__))
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __FILE__)

Dir['tasks/**/*.rake'].each do |tasks|
  load tasks
end

task :default => [:rubocop, :spec]