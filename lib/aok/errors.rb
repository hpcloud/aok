module Aok
  module Errors

    class AokError < RuntimeError
      attr_accessor :error, :error_description
      def http_status
        500
      end

      def http_headers
        {
          'Content-Type' => 'application/json'
        }
      end

      def body
        {
          'error' => error,
          'error_description' => error_description
        }.to_json
      end
    end

    class Unauthorized < AokError
      def initialize(desc='Bad credentials')
        @error = 'unauthorized'
        @error_description = desc
      end

      def http_headers
        super.merge({
          'WWW-Authenticate' => 
            %Q{Bearer realm="oauth", error="#{error}", error_description="#{error_description}"}
        })
      end

      def http_status
        401
      end
    end
  end

end