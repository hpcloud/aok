task :spec => "spec:all"

namespace :spec do
  task :all do
    run_specs
  end

  task :path, [:path] do |t, args|
    run_specs({:path => args.path})
  end

  task :format, [:format] do |t, args|
    run_specs({:format => args.format})
  end

  def run_specs(options = {})
    options[:path] ||= 'spec/unit'
    options[:format] ||= 'RSpec::Instafail'
    puts "Running rspec against '#{options[:path]}'..."
    sh "bundle exec rspec #{options[:path]} --require rspec/instafail --format RSpec::Instafail  --format RspecJunitFormatter --out rspec.xml"
  end
end