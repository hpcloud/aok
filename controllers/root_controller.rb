class RootController < ApplicationController

  get '/?' do
    redirect("https://#{CCConfig[:external_uri]}")
  end

  get '/auth' do
    redirect "/auth/#{settings.strategy}"
  end

  post '/auth/:provider/callback' do
    email = auth_hash[:info][:email]
    user = env['omniauth.identity']
    set_current_user(user)

    if env["aok.block"] # legacy login
      env["aok.block"].call(user)
      return
    end

    if env["aok.no_openid"] # legacy login
      return {:email => email}.to_json
    end

    redirect '/openid/complete'
  end

  get '/auth/failure' do
    # legacy login failures handles by Aok::Config::Strategy::FailureEndpoint
    clear_current_user
    redirect '/openid/complete'
  end



end