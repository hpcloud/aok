require 'spec_helper'

describe UaaSpringSecurityUtils::PathRules do

  context "with authorized token request" do
    before do
      filepath = File.join(File.dirname(File.expand_path(__FILE__)), 'test_rules.yml')
      @rules = UaaSpringSecurityUtils::PathRules.new(filepath)
      @rules.logger = Logger.new(STDOUT)
      @rules.logger.level = Logger::DEBUG
      @rules.path_rules.should_not be_empty
    end

    let(:request) {
      Rack::Request.new({
        "HTTP_AUTHORIZATION" => "Bearer asdfjhasdfhasdf",
        "PATH_INFO" => "/oauth/token",
        "REQUEST_METHOD" => "GET",
      })
    }

    it 'match a path' do
      @rules.match_path(request).should_not be_nil
    end

  end


end
