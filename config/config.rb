require 'kato/logging'
require 'kato/doozer'
Kato::Logging.logdev = STDERR
%W{
  environment
  appconfig
  strategy
  database
}.each{|lib|require File.expand_path('../'+lib, __FILE__)}
