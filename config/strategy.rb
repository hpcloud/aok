module Ehok
  module Config
    def self.initialize_strategy
      strategy_config = Kato::Doozer.get_component_config_value("ehok", "strategy")
      case strategy_config
      when 'builtin'
        ApplicationController.use OmniAuth::Strategies::Identity
        ApplicationController.set :strategy, :identity, :fields => [:email], :title => "Login"
      when 'developer'
        ApplicationController.use OmniAuth::Strategies::Developer
        ApplicationController.set :strategy, :developer
      else
        abort "Ehok cannot start. Strategy was #{strategy_config.inspect} -- not a valid strategy."
      end
      puts "Initialized #{ApplicationController.strategy} authentication strategy."
    end
  end
end