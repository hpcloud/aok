require 'time'
require 'uaa'
class UaaController < ApplicationController

  get '/?' do
    return 'Hello World'
  end

  get '/login' do
    return 200,
      {"Content-Type" => "application/json"},
      { :timestamp => Time.now.xmlschema,
        # TODO: move this commit to memory instead of reading the file
        :commit_id => File.read(File.dirname(__FILE__) + '/../GITDESCRIBE-PKG').strip,
        :prompts => {
          :username => ["text","Username"],
          :password => ["password","Password"]
        }
      }.to_json
  end

  post '/oauth/token' do 
    # params =~ {"grant_type"=>"password", "username"=>"bob_johnson", "password"=>"zyzzyva"}
    return 200, 
      {'Content-Type' => 'application/json'}, 
      {
        :token_type => 'bearer', 
        :access_token => CF::UAA::TokenCoder.encode(
          {
            :aud => 'cloud_controller',
            :user_id => 'abc-1234',
            :email => 'stackato@stackato.com',
            :exp => Time.now.to_i + 1_000_000_000
          }, 
          {
            :skey => 'tokensecret'
          }
        )
      }.to_json
  end

end