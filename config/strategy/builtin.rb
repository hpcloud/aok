module ::Aok; module Config; module Strategy

  STRATEGIES << 'builtin'
  STRATEGIES_DIRECT[:builtin] = {}

  class Builtin < Base
    def self.setup
      require 'omniauth-identity'
      ApplicationController.use OmniAuth::Strategies::Identity, DEFAULT_OPTIONS
      ApplicationController.set :strategy, :identity
    end
  end

end; end; end
