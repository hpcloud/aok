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

      [:allowed_groups, :admin_groups].each do |key|
        if options.key? key
          unless options[key].nil? or options[key].kind_of?(Array)
            abort "The LDAP strategy option #{key} should be an Array[String], not #{options[key].class}"
          end
        end
      end

      ApplicationController.use OmniAuth::Strategies::LDAP, options
      ApplicationController.set :strategy, :ldap
    end

    def valid_group_data?(group_data)
      group_data && group_data.kind_of?(Array) && group_data.length > 0
    end

    def filter_callback(the_env)
      allowed_groups = AppConfig[:strategy][:ldap][:allowed_groups]
      admin_groups = AppConfig[:strategy][:ldap][:admin_groups]

      if valid_group_data? allowed_groups
        if valid_group_data? admin_groups
          allowed_groups.concat(admin_groups)
        end 

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
        auto_add_user_to_admin_group user
      end

      admin_groups = AppConfig[:strategy][:ldap][:admin_groups]
      if valid_group_data? admin_groups
        has_admin_via_group = groups_intersect?(admin_groups, users_groups(the_env))
        has_admin_via_group ? auto_add_user_to_admin_group(user) : auto_remove_user_from_admin_group(user)
      end
    end

    def auto_add_user_to_admin_group user
      admin_group = Group.find_by_name!('cloud_controller.admin')
      unless user.groups.include? admin_group
        user.groups << admin_group
        user.auto_admin = true
        user.save!
        logger.info "Automatically granted #{user.username} admin privileges due to configured LDAP admin group access rules."
      end
    end

    def auto_remove_user_from_admin_group user
      if user.auto_admin
        admin_group = Group.find_by_name!('cloud_controller.admin')
        if user.groups.include? admin_group
          user.groups.delete(admin_group)
          user.auto_admin = false
          user.save!
          logger.info "Automatically revoked admin privileges from #{user.username} due to configured LDAP admin group access rules."
        end
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
