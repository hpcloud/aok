require 'omniauth'
module Aok
  module Config
    module Strategy

      class FailureEndpoint < OmniAuth::FailureEndpoint
        require 'sinatra'
        include Sinatra::Helpers
        def call
          if env["aok.block"] # legacy login
            env["aok.block"].call(nil)
            return
          end
          redirect_to_failure
        end

        def request
          @request ||= Sinatra::Request.new(env)
        end

        def redirect_to_failure
          message_key = env['omniauth.error.type']
          new_path = uri("/uaa/auth/failure?message=#{message_key}#{origin_query_param}#{strategy_name_query_param}")
          Rack::Response.new(["302 Moved"], 302, 'Location' => new_path).finish
        end
      end
      OmniAuth.config.on_failure = Aok::Config::Strategy::FailureEndpoint

      # All valid strategies-- individual strategies will add themselves to this
      STRATEGIES = []

      # Strategies for which we are capable of doing legacy client login with name/pw,
      # and the corresponding mapping of field names from id/secret if needed
      # individual strategies will add themselves to this
      STRATEGIES_DIRECT = {
        :default => {
          :id => :auth_key,
          :secret => :password
        },
      }

      DEFAULT_OPTIONS = {
        :title => "Sign In",
        :callback_path => '/uaa/login.do'
      }

      class << self
        def initialize_strategy
          unless STRATEGIES.include? AppConfig[:strategy][:use]
            abort "AOK cannot start. Strategy was #{AppConfig[:strategy][:use].inspect} -- not a valid strategy."
          end

          strategy_klass.setup

          unless ApplicationController.strategy
            abort "AOK cannot start. No authentication strategy set."
          end
          puts "Initialized #{ApplicationController.strategy} authentication strategy."
        end

        def direct_login_enabled?
          STRATEGIES_DIRECT.key? AppConfig[:strategy][:use].to_sym
        end

        def id_field_for_strategy
          direct_strategy_config[:id] || STRATEGIES_DIRECT[:default][:id]
        end

        def secret_field_for_strategy
          direct_strategy_config[:secret] || STRATEGIES_DIRECT[:default][:secret]
        end

        def direct_strategy_config
          STRATEGIES_DIRECT[AppConfig[:strategy][:use].to_sym]
        end

        # test method
        def remove
          strategy = ApplicationController.settings.strategy.to_s
          klass = OmniAuth::Strategies.const_get("#{OmniAuth::Utils.camelize(strategy)}")
          ApplicationController.instance_variable_get('@middleware').delete_if{|m|m.first == klass}
        end

        def strategy_klass
          const_get(OmniAuth::Utils.camelize(AppConfig[:strategy][:use]))
        end

      end

    end
  end
end

%W{base ldap google_apps builtin developer}.each do |l|
  require_relative "strategy/#{l}"
end
