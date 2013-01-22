module Aok
  module Config
    class << self
      attr_reader :direct_login_enabled
      def initialize_strategy
        case AppConfig[:strategy][:use]
        when 'builtin'
          ApplicationController.use OmniAuth::Strategies::Identity
          ApplicationController.set :strategy, :identity, :fields => [:email], :title => "Login"
          @direct_login_enabled = true
        when 'ldap'
          ApplicationController.use OmniAuth::Strategies::LDAP
          options = AppConfig[:strategy][:ldap]
          ApplicationController.set :strategy, :ldap, {
            :title => "Login",

          }
          @direct_login_enabled = true
        # when 'developer'
        #   puts "WARNING Developer strategy is wide-open access. Completely insecure!"
        #   ApplicationController.use OmniAuth::Strategies::Developer
        #   ApplicationController.set :strategy, :developer
        else
          abort "Aok cannot start. Strategy was #{strategy_config.inspect} -- not a valid strategy."
        end
        puts "Initialized #{ApplicationController.strategy} authentication strategy."
      end
    end
  end
end
