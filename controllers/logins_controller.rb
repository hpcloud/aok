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
    data = read_json_body
    direct_login(data['email'], data['password'])
  end

end
