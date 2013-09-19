class RootController < ApplicationController

  get '/?' do
    redirect("https://#{CCConfig[:external_uri]}")
  end

  get '/auth' do
    redirect "/auth/#{settings.strategy}"
  end




end