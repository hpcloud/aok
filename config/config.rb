require 'kato/logging'
require 'kato/doozer'
Kato::Logging.log_to_stderr = true
%W{
  appconfig
  strategy
  database
}.each{|lib|require File.expand_path('../'+lib, __FILE__)}
