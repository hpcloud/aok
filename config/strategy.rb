require 'omniauth'
module Aok
  module Config
    module Strategy

      class FailureEndpoint
        def self.call(the_env)
          if the_env["aok.block"] # legacy login
            the_env["aok.block"].call(nil)
            return
          end
          return 403 if the_env["aok.no_openid"] # legacy login
          OmniAuth::FailureEndpoint.call(the_env) # default behavior
        end
      end
      OmniAuth.config.on_failure = Aok::Config::Strategy::FailureEndpoint

      # All valid strategies
      STRATEGIES = %W{
        builtin
        ldap
        google_apps
        developer
      }

      # Strategies for which we are capable of doing legacy client login with name/pw,
      # and the corresponding mapping of field names from id/secret if needed
      STRATEGIES_DIRECT = {
        :default => {
          :id => :email,
          :secret => :password
        },
        :builtin => {
          :id => :auth_key
        },
        :ldap => {
          :id => :username
        },
        :developer => {
        }
      }

      DEFAULT_OPTIONS = {
        :title => "Sign In"
      }

      class << self
        def initialize_strategy
          unless STRATEGIES.include? AppConfig[:strategy][:use]
            abort "AOK cannot start. Strategy was #{AppConfig[:strategy][:use].inspect} -- not a valid strategy."
          end

          method(AppConfig[:strategy][:use]).call

          unless ApplicationController.strategy
            abort "AOK cannot start. No authentication strategy set."
          end
          puts "Initialized #{ApplicationController.strategy} authentication strategy."
        end

        def builtin
          require 'omniauth-identity'
          ApplicationController.use OmniAuth::Strategies::Identity, DEFAULT_OPTIONS.merge({
            :fields => [:email]
          })
          ApplicationController.set :strategy, :identity
        end

        def ldap
          require 'omniauth-ldap'
          options = AppConfig[:strategy][:ldap].merge(DEFAULT_OPTIONS)

          if options.key? :name_proc
            proc = options[:name_proc]
            begin
              proc = eval(proc) unless proc.kind_of? Proc
            rescue Exception => e
              abort "#{e.inspect} raised when trying to eval ldap name_proc"
            end
            abort "ldap name_proc must be a Ruby Proc" unless proc.kind_of? Proc
            unless proc.arity == 1
              abort "ldap name_proc must accept exactly one argument."
            end
            begin
              proc.call('foo')
            rescue Exception => e
              abort "ldap name_proc raised #{e.inspect} in a simple test (name_proc.call('foo')). The proc must accept arbitrary user input safely. Please fix."
            end
            options[:name_proc] = proc
          end

          config = OmniAuth::Strategies::LDAP.class_variable_get '@@config'
          if options.key? :email
            config['email'] = options[:email]
          end

          ApplicationController.use OmniAuth::Strategies::LDAP, options
          ApplicationController.set :strategy, :ldap
        end

        def google_apps
          require 'omniauth-google-apps'
          options = AppConfig[:strategy][:google_apps].merge(DEFAULT_OPTIONS)
          [:domain].each do |option_key|
            unless options.key?(option_key) && !options[option_key].empty?
              abort "Google login requires that the `#{option_key}` configuration option is set."
            end
          end

          ApplicationController.use OmniAuth::Builder do
            provider :google_apps, :domain => options[:domain]
          end
          ApplicationController.set :strategy, :google_apps

          OpenID.fetcher.ca_file = "/etc/ssl/certs/ca-certificates.crt"
        end

        def developer
          options = DEFAULT_OPTIONS.merge({:fields => [:email]})
          puts "WARNING Developer strategy is wide-open access. Completely insecure!"
          ApplicationController.use OmniAuth::Strategies::Developer, options
          ApplicationController.set :strategy, :developer
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
      end

    end
  end
end
