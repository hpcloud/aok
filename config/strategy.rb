module Aok
  module Config
    module Strategy
      # All valid strategies
      STRATEGIES = %W{
        builtin
        ldap
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
        },
        :ldap => {
          :id => :username
        },
        :developer => {
        }
      }

      class << self
        def initialize_strategy
          unless STRATEGIES.include? AppConfig[:strategy][:use]
            abort "AOK cannot start. Strategy was #{strategy_config.inspect} -- not a valid strategy."
          end

          method(AppConfig[:strategy][:use]).call

          unless ApplicationController.strategy
            abort "AOK cannot start. No authentication strategy set."
          end
          puts "Initialized #{ApplicationController.strategy} authentication strategy."
        end

        def builtin
          ApplicationController.use OmniAuth::Strategies::Identity
          ApplicationController.set :strategy, :identity, {
            :fields => [:email], 
            :title => "Login"
          }
        end

        def ldap
          options = {
            :title => "Login",
          }.merge(AppConfig[:strategy][:ldap])

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
          ApplicationController.use OmniAuth::Strategies::LDAP, options
          ApplicationController.set :strategy, :ldap
        end

        def developer
          puts "WARNING Developer strategy is wide-open access. Completely insecure!"
          ApplicationController.use OmniAuth::Strategies::Developer, :fields => [:email]
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
