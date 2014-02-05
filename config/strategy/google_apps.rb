module ::Aok; module Config; module Strategy
  STRATEGIES << 'google_apps'

  class GoogleApps < Base
    def self.setup
      require 'omniauth-google-apps'
      options = DEFAULT_OPTIONS.merge(AppConfig[:strategy][:google_apps])
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
  end

end; end; end
