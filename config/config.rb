require 'kato/logging'
Kato::Logging.logdev = STDERR
%W{
  environment
  appconfig
  strategy
  database
}.each{|lib|require File.expand_path('../'+lib, __FILE__)}
