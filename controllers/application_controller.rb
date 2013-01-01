require 'logger'
class ApplicationController < Sinatra::Base
  helpers ApplicationHelper
  set :views, File.expand_path('../../views', __FILE__)

  configure :production, :development do
    enable :sessions
  end
  configure :development do
    set :logging, Logger::DEBUG
  end

  before do
    headers({
      'X-XRDS-Location' => url("/openid/idp_xrds", true, false)
    })
  end

  def self.get_and_post(*args, &block)
    get(*args, &block)
    post(*args, &block)
  end

end