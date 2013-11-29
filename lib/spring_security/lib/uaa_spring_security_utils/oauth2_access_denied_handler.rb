module UaaSpringSecurityUtils
  class OAuth2AccessDeniedHandler

    def self.handle(path, security_context)
      if not security_context.authenticated?

        type = path.entry_point.type || 'Bearer'
        realm = path.entry_point.realm
        if security_context.invalid_client_identifier
          raise Aok::Errors::InvalidClient.new(type, realm)
        end

        raise Aok::Errors::Unauthorized.new(
          "An Authentication object was not found in the SecurityContext",
          type,
          realm
        )

      end

      raise Aok::Errors::AccessDenied.new(
        "You are not permitted to access this resource."
      )
    end

  end
end
