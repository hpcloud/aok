module Aok
  module Config
    # All valid strategies
    STRATEGIES = %W{
      builtin
      ldap
    }
    # Strategies for which we are capable of doing legacy client login with name/pw
    STRATEGIES_DIRECT = %W{
      builtin
      ldap
    }

    class << self
      attr_reader :direct_login_enabled
      def initialize_strategy
        unless STRATEGIES.include? AppConfig[:strategy][:use]
          abort "AOK cannot start. Strategy was #{strategy_config.inspect} -- not a valid strategy."
        end

        method(AppConfig[:strategy][:use]).call
        @direct_login_enabled = STRATEGIES_DIRECT.include? AppConfig[:strategy][:use]

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

      # def developer
      #   puts "WARNING Developer strategy is wide-open access. Completely insecure!"
      #   ApplicationController.use OmniAuth::Strategies::Developer
      #   ApplicationController.set :strategy, :developer
      # end

    end
  end
end
