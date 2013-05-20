require 'uri'
class LoginsController < ApplicationController

  before do
    require_local

    unless Aok::Config::Strategy.direct_login_enabled?
      # code below must match error number in CC's CloudError class
      halt 400, "Login with password is not enabled using this strategy. Code 13444."
    end
  end

  class << self
    attr_reader :middleware
  end

  post '/?' do
    # Take the credentials that were posted to us and simulate a form
    # submission on the configured omniauth strategy. We basically
    # rewinding the Rack call stack, mapping the credentials we were
    # given in to what OmniAuth is expecting for this strategy, and
    # then replaying Rack starting at the OmniAuth callback.

    # Put together our request body that looks like a form submission
    data = read_json_body
    id_field = Aok::Config::Strategy.id_field_for_strategy
    secret_field = Aok::Config::Strategy.secret_field_for_strategy
    form_hash = {id_field => data['email'], secret_field => data['password']}
    form_string = URI.encode_www_form(form_hash)
    form_io = StringIO.new(form_string)

    # Find what strategy we're using
    strategy = settings.strategy.to_s
    klass = OmniAuth::Strategies.const_get("#{OmniAuth::Utils.camelize(strategy)}")
    middleware = ApplicationController.middleware.find{|m| m.first == klass}
    middleware_options = middleware[1].first

    # Fake out Rack to think we're on the auth callback with our synthesized form body
    path = "/auth/#{strategy}/callback"

    session # need this to ensure env['rack.session'] is set, needed by omniauth

    env.merge!(
      "REQUEST_METHOD"=>"POST", 
      "REQUEST_PATH" => path, 
      "PATH_INFO" => path,
      "REQUEST_URI" => path,
      "rack.input" => form_io,
      "CONTENT_TYPE" => "application/x-www-form-urlencoded",
      "aok.no_openid" => true # just return a status code, no openid redirects
    )
    
    # Call the middleware, which will then call up in to the auth code
    # in ApplicationController. The results can be returned directly.
    klass.new(self, middleware_options).call!(env)
  end

end
