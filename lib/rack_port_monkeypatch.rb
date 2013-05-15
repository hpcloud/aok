# FIXME: remove when bug 99010 is fixed
# Work around bug in node-http-proxy, where X-Forwarded-Port is set incorrectly
module Rack
  class Request
    def port
      if port = host_with_port.split(/:/)[1]
        port.to_i
      elsif @env.has_key?("HTTP_X_FORWARDED_HOST") || @env.has_key?("HTTP_X_FORWARDED_PORT")
        DEFAULT_PORTS[scheme]
      else
        @env["SERVER_PORT"].to_i
      end
    end
  end
end
