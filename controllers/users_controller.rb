class UsersController < ApplicationController

  get '/?' do
    raise NotImplemented
  end

  post '/?' do
    raise NotImplemented
  end


  def user_xrds
    types = [
             OpenID::OPENID_2_0_TYPE,
             OpenID::OPENID_1_0_TYPE,
             OpenID::SREG_URI,
            ]

    render_xrds(types)
  end


end