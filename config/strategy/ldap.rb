module ::Aok; module Config; module Strategy

  STRATEGIES << 'ldap'
  STRATEGIES_DIRECT[:ldap] = {
      :id => :username
    }
  class LDAP < Base; class << self
    def setup
      require 'omniauth-ldap'
      options = DEFAULT_OPTIONS.merge(AppConfig[:strategy][:ldap])

      if options.key? :name_proc
        proc = options[:name_proc]
        begin
          proc = eval(proc) unless proc.kind_of? Proc
        rescue Exception => e
          abort "#{e.inspect} raised when trying to eval ldap name_proc"
        end
        abort "ldap name_proc must be a Ruby Proc" unless proc.kind_of? Proc
        unless proc.arity == 1
          abort "ldap name_proc must accept exactly one argument."
        end
        begin
          proc.call('foo')
        rescue Exception => e
          abort "ldap name_proc raised #{e.inspect} in a simple test (name_proc.call('foo')). The proc must accept arbitrary user input safely. Please fix."
        end
        options[:name_proc] = proc
      end

      config = OmniAuth::Strategies::LDAP.class_variable_get '@@config'
      if options.key? :email
        config['email'] = options[:email]
      end

      ApplicationController.use OmniAuth::Strategies::LDAP, options
      ApplicationController.set :strategy, :ldap
    end

    def filter_callback(the_env)
      allowed_groups = AppConfig[:strategy][:ldap][:allowed_groups]
      if allowed_groups && allowed_groups.kind_of?(Array) && allowed_groups.length > 0
        has_access_via_group = groups_intersect?(allowed_groups, users_groups(the_env))
        unless has_access_via_group
          raise Aok::Errors::AccessDenied.new('Unauthorized via group security rules')
        end
      end

      # set username by modifying omniauth.auth in place
      username = the_env['omniauth.auth'][:extra][:raw_info][AppConfig[:strategy][:ldap][:uid]]
      username = username.kind_of?(Array) ? username.first : username
      the_env['omniauth.auth'][:info][:nickname] = username
    end

    def authorization_callback(the_env, user)
      config_admin = AppConfig[:strategy][:ldap][:admin_user]

      if config_admin && user.username.downcase == config_admin.downcase
        add_user_to_admin_group user
      end

      admin_groups = AppConfig[:strategy][:ldap][:admin_groups]
      if admin_groups && admin_groups.kind_of?(Array) && admin_groups.length > 0
        has_admin_via_group = groups_intersect?(admin_groups, users_groups(the_env))
        add_user_to_admin_group(user) if has_admin_via_group
      end

    end

    def add_user_to_admin_group user
      admin_group = Group.find_by_name!('cloud_controller.admin')
      unless user.groups.include? admin_group
        user.groups << admin_group
        user.save!
      end
    end

    def users_groups the_env
      users_groups = the_env['omniauth.auth'][:extra][:groups]
      if users_groups.nil? 
        logger.error <<-END
          LDAP group security appears to be configured as allowed_groups or 
          admin_groups has been set, but no groups returned for user. Check
          group_query and group_attribute config. #{the_env['omniauth.auth'].inspect}
          END
        raise Aok::Errors::AccessDenied.new('Unauthorized via group security rules')
      end
      return users_groups
    end

    # arguments are arrays
    def groups_intersect?(g1, g2)
      !(g1 & g2).empty?
    end

  end; end

end; end; end
