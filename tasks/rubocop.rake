
task :rubocop => 'rubocop:all'

namespace :rubocop do
  task :all do
    run_rubocop(nil)
  end

  desc 'Runs rubocop against AOK'
  def run_rubocop(path)
    require 'rubocop/rake_task'
    RuboCop::RakeTask.new do |task|
      if path
        task.patterns = ['controllers/**/*.rb',
                         'config/**/*.rb',
                         'helpers/**/*.rb',
                         'lib/**/*.rb',
                         'models/**/*.rb']
      end
      # don't abort rake on failure
      task.fail_on_error = false
    end
  end
end