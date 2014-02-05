module ::Aok; module Config; module Strategy

  STRATEGIES << 'developer'
  STRATEGIES_DIRECT[:developer] = {}

  class Developer < Base
    def self.setup
      options = DEFAULT_OPTIONS.merge({:fields => [:username]})
      puts "WARNING Developer strategy is wide-open access. Completely insecure!"
      ApplicationController.use OmniAuth::Strategies::Developer, options
      ApplicationController.set :strategy, :developer
    end
  end

end; end; end
