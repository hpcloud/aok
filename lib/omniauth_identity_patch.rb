require "omniauth/strategies/identity"

module OmniAuth
  module Strategies
    # This is a customized Identity strategy for Omniauth without the registration feature.
    # See https://github.com/intridea/omniauth-identity/pull/21

    class Identity
      # Disable registration
      def request_phase
        OmniAuth::Form.build(
          :title => (options[:title] || "Identity Verification"),
          :url => callback_path
        ) do |f|
          f.text_field 'Email', 'auth_key'
          f.password_field 'Password', 'password'
        end.to_response
      end

      # Deactivate registration forms, so that 404 is thrown.
      def other_phase
        call_app!
      end
    end
  end
end