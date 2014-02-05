module ::Aok; module Config; module Strategy

  class Base
    class << self
      def setup
        raise 'must be implemented in inheriting class'
      end

      def filter_callback(the_env)
      end

      def authorization_callback(the_env, user)
      end

      def logger
        ApplicationController.logger
      end
    end
  end

end; end; end
