module LoginEndpoint
  def self.included(base)

    # Internal Login
    # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#internal-login-post-logindo
    base.post '/uaa/login.do' do
      user = env['omniauth.identity']
      if user.nil?
        # using something other than the Identity strategy (like LDAP)
        Aok::Config::Strategy.strategy_klass.filter_callback(env)

        info = env['omniauth.auth'][:info]
        username = info[:nickname]

        if username.nil?
          raise "Couldn't find a username to use for this user! #{env['omniauth.auth'].inspect}"
        end
        user = Identity.find_by_username(username)
        if user.nil?
          user = Identity.create!(
            username: username,
            email: info[:email],
            given_name: info[:first_name],
            family_name: info[:last_name],
            )
        end

        Aok::Config::Strategy.strategy_klass.authorization_callback(env, user)

      end

      set_current_user(user)

      if env["aok.block"] # legacy login
        env["aok.block"].call(user)
        return
      end

      destination = nil
      if request.env['omniauth.origin']
        destination = CGI.unescape(request.env['omniauth.origin'])
        logger.debug "Found stored origin for redirect: #{destination.inspect}"
        unless destination =~ /^\/uaa/
          # Redirects within AOK only
          logger.debug "Don't like the looks of that redirect; overwriting..."
          destination = nil
        end
      end
      destination ||= '/uaa'
      redirect to(destination), 302
    end
  end
end
