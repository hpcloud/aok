class LoginsController < ApplicationController

  post '/?' do
    require_local
    data = read_json_body
    if Identity.authenticate(data['email'], data['password'])
      return 204
    end
    return 403
  end

end