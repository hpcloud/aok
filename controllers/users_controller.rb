class UsersController < ApplicationController

  post '/?' do
    require_local
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

  delete '/:username' do
    require_local
    user = Identity.find_by_email(params[:username])
    return 404 unless user
    user.destroy
    return 204
  end

  put '/:username' do
    require_local
    user = Identity.find_by_email(params[:username])
    return 404 unless user
    data = read_json_body
    if data['password']
      user.password = user.password_confirmation = data['password']
    end
    if user.changed? && !user.save
      return 400, {'Content-Type' => 'application/json'}, user.errors.full_messages.to_json
    end
    return 204
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