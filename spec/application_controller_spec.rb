require 'spec_helper'

def app
  ApplicationController
end

describe 'Application Controller' do
  it "says go away!" do
    get '/'
    last_response.status.should eq(403)
    last_response.body.should eq("{\"error\":\"access_denied\",\"error_description\":\"You are not allowed to access this resource.\"}")
  end
end
