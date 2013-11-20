module UaaSpringSecurityUtils
  class UaaRequestMatcher
    # http://docs.spring.io/spring-security/site/docs/3.1.x/reference/ns-config.html#filter-stack
    FILTER_ORDER = %W{
      CHANNEL_FILTER
      SECURITY_CONTEXT_FILTER
      CONCURRENT_SESSION_FILTER
      LOGOUT_FILTER
      X509_FILTER
      PRE_AUTH_FILTER
      CAS_FILTER
      FORM_LOGIN_FILTER
      BASIC_AUTH_FILTER
      SERVLET_API_SUPPORT_FILTER
      REMEMBER_ME_FILTER
      ANONYMOUS_FILTER
      SESSION_MANAGEMENT_FILTER
      EXCEPTION_TRANSLATION_FILTER
      FILTER_SECURITY_INTERCEPTOR
      SWITCH_USER_FILTER
    }


  end
end
