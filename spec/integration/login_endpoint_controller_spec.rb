require 'spec_helper'

def app
  RootController
end

describe 'LoginEndpoint Controller' do

  get '/'
  puts "#{last_response.body}"

  it "fails yo" do
    2.should == 1
  end
end