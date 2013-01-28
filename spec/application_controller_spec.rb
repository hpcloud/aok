require 'spec_helper'

def app
  ApplicationController
end

describe 'Application Controller' do
  it "says AOK!" do
    get '/'
    last_response.should be_ok
    last_response.body.should == '<h1>AOK!</h1>'
  end
end