module Aok
  module Errors

    class AokError < RuntimeError
      attr_accessor :http_status, :http_headers, :error, :error_description

      def initialize(error="unknown_error", desc="An unknown error occurred.")
        @error = error
        @error_description = desc
        @http_status = 500
        @http_headers = {
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
      def initialize(desc='Bad credentials', type='Bearer', realm="oauth")
        super()
        @http_status = 401
        @error = 'unauthorized'
        @error_description = desc
        @http_headers = http_headers.merge({
          'WWW-Authenticate' =>
            %Q{#{type} realm="#{realm}", error="#{error}", error_description="#{error_description}"}
        })
      end

    end

    class NotImplemented < AokError
      def initialize(desc='You have reached a stub API endpoint that has not yet been implemented in AOK.')
        super()
        @http_status = 501
        @error = 'Not Implemented'
        @error_description = desc
      end
    end

    class ScimFilterError < AokError
      def initialize(desc='Invalid SCIM filter')
        super('scim_filter_error', desc)
      end
    end

    class NoGettingCredentials < Unauthorized
      def initialize(desc="Credentials must be sent by (one of methods): [POST]")
        super desc
      end
    end

  end

end
