%W{
  uaa_spring_security_utils/version
  uaa_spring_security_utils/util
  uaa_spring_security_utils/path
  uaa_spring_security_utils/uaa_request_matcher
  uaa_spring_security_utils/config_parser
  uaa_spring_security_utils/path_rules
  uaa_spring_security_utils/oauth2_access_denied_handler
}.each{|lib| require_relative lib}


