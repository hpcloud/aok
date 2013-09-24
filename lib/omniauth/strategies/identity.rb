require "omniauth/strategies/identity"

module OmniAuth
  module Strategies
    # This is a customized Identity strategy for Omniauth without the registration feature.
    # See https://github.com/intridea/omniauth-identity/pull/21

    # TODO: Subclass this strategy instead of monkey-patching it.
    class Identity
      # Disable registration
      def request_phase
        OmniAuth::Form.build(
          :title => (options[:title] || "Identity Verification"),
          :url => callback_path
        ) do |f|
          f.text_field model.auth_key.titlecase, model.auth_key
          f.password_field 'Password', 'password'
          f.html "\n\n<!-- This is to satisfy the UAA unit tests: /login.do -->\n\n"
        end.to_response
      end

      # Deactivate registration forms, so that 404 is thrown.
      def other_phase
        call_app!
      end

      def callback_phase
        return fail!(:invalid_credentials) unless identity
        # stash the identity we just validated
        self.env['omniauth.identity'] = @identity
        super
      end

      def identity
        @identity ||= model.authenticate(request[model.auth_key], request['password'])
      end

    end
  end
end
