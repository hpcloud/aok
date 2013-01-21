class LoginsController < ApplicationController

  before do
    require_local
    
    unless Ehok::Config.direct_login_enabled
      halt 400, "Login with password is not enabled using this strategy."
    end
  end

  post '/?' do
    data = read_json_body
    # XXX This is currently only going to work with the built-in db. 
    # Will need a more general solution that goes through OmniAuth
    if Identity.authenticate(data['email'], data['password'])
      return 204
    end
    return 403
  end

end