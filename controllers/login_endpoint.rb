module LoginEndpoint
  def self.included(base)

    # Internal Login
    # https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#internal-login-post-logindo
    base.post '/uaa/login.do' do
      email = auth_hash[:info][:email]
      user = env['omniauth.identity']
      if user.nil?
        # using something other than the Identity strategy (like LDAP)  
        info = env['omniauth.auth'][:info]
        username = info[:nickname]
        if env['omniauth.auth'][:provider] == 'ldap'

          allowed_groups = AppConfig[:strategy][:ldap][:allowed_groups]
          if allowed_groups && allowed_groups.kind_of?(Array) && allowed_groups.length > 0

            users_groups = env['omniauth.auth'][:extra][:groups]
            if users_groups.nil? 
              logger.error "LDAP group security appears to be configured as allowed_groups has been set but no groups 
                returned for user, check group_query and group_attribute config. #{env['omniauth.auth'].inspect}"
              raise Aok::Errors::AccessDenied.new('Unauthorized via group security rules')
            end

            has_access_via_group = allowed_groups.index { |group| users_groups.include?(group) }
            if has_access_via_group == nil
              raise Aok::Errors::AccessDenied.new('Unauthorized via group security rules')
            end
          end

          username = env['omniauth.auth'][:extra][:raw_info][AppConfig[:strategy][:ldap][:uid]]
          username = username.kind_of?(Array) ? username.first : username
        end
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
        if env['omniauth.auth'][:provider] == 'ldap'
          config_admin = AppConfig[:strategy][:ldap][:admin_user]
          if config_admin && username.downcase == config_admin.downcase
            admin_group = Group.find_by_name!('cloud_controller.admin')
            unless user.groups.include? admin_group
              user.groups << admin_group
              user.save!
            end
          end
        end
      end
      set_current_user(user)

      if env["aok.block"] # legacy login
        env["aok.block"].call(user)
        return
      end

      if env["aok.no_openid"] # legacy login
        return {:email => email}.to_json
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
