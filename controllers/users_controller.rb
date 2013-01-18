class UsersController < ApplicationController

  #XXX: Authentication needed!!
  post '/?' do
    data = read_json_body
    user = Identity.new
    user.email = data['email']
    user.password = user.password_confirmation = data['password']
    if user.save
      return 204
    else
      return 400, {'Content-Type' => 'application/json'}, user.errors.full_messages.to_json
    end
  end

  get '/:username' do
    return user_xrds
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