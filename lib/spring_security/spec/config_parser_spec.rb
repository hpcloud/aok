require 'spec_helper'

describe UaaSpringSecurityUtils::ConfigParser do
  it "should parse successfully" do
    glob = File.dirname(File.expand_path(__FILE__)) + "/../../uaa/uaa/src/main/webapp/**/*.xml"
    @config = UaaSpringSecurityUtils::ConfigParser.new glob
    @config.logger = Logger.new(STDOUT)
    @config.logger.level = Logger::DEBUG
    @config.parse
    @config.path_rules.size.should eq(27)
    @config.to_yaml.should_not be_empty
  end



end
