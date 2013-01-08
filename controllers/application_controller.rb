require 'logger'
class ApplicationController < Sinatra::Base
  helpers ApplicationHelper, CurrentUserHelper
  set :views, File.expand_path('../../views', __FILE__)
  set :logging, Logger::INFO

  # XXX: get secret from doozer
  use Rack::Session::Cookie, :secret => SecureRandom.urlsafe_base64(128)

  configure :development do
    set :logging, Logger::DEBUG
    puts "SETTING UP DEVELOPMENT ENVIRONMENT"
    use OmniAuth::Strategies::Developer
    set :strategy, :developer
  end

  ActiveRecord::Base.establish_connection(Ehok::Config.get_database_config)

  before do
    headers({
      'X-XRDS-Location' => url("/openid/idp_xrds", true, false)
    })
  end

  def self.get_and_post(*args, &block)
    get(*args, &block)
    post(*args, &block)
  end

  get '/auth' do
    redirect "/auth/#{settings.strategy}"
  end

  post '/auth/:provider/callback' do
    email = auth_hash[:info][:email]
    user = User.find_by_email(email)
    unless user
      user = User.new
      user.email = email
      user.save!
    end
    set_current_user(user)
    redirect '/openid/complete'
  end

  protected

  def auth_hash
    request.env['omniauth.auth']
  end

end