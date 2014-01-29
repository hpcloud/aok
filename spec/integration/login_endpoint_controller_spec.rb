require 'spec_helper'

def app
  RootController
end

describe 'LoginEndpoint Controller' do


  it "fails yo" do
    get '/'
    puts "#{last_response.body}"

    2.should == 1
  end
end
