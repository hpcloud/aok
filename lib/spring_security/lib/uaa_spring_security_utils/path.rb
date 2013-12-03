require 'pp'
module UaaSpringSecurityUtils
  class Path

    attr_reader :path,
      :entry_point,
      :security,
      :intercept,
      :decision_manager,
      :decision_mode,
      :subject

    SCOPE_ENFORCEMENT = /scope=([^,]+)|#oauth2.hasScope\('([^,]+)'\)/
    ROLE_ENFORCEMENT  = /ROLE_([^,]+)|hasRole\('([^,]+)'\)/
    SELF_ENFORCEMENT  = /user=self/
    FULL_AUTHENTICATION = /IS_AUTHENTICATED_FULLY|isFullyAuthenticated\(\)/
    MODE_UNANIMOUS = "org.springframework.security.access.vote.UnanimousBased"
    MODE_AFFIRMATIVE = "org.springframework.security.access.vote.AffirmativeBased"

    class PathClass
      include Util
      def initialize(hash)
        @hash = hash || {}
        @hash.default_proc = Proc.new{|h, key| h[key] = Hash.new(&h.default_proc)}
      end

      def property(prop_name)
        prop = arrayize(@hash['property']).detect{|p|p['name'] == prop_name}
        return nil unless prop
        prop['value']
      end
    end

    class EntryPoint < PathClass
      attr_reader :handler, :type, :realm
      def initialize(hash)
        super
        @handler = @hash['class']
        @realm = property('realmName')
        @type = property('typeName')
      end
    end

    class Intercept < PathClass
      attr_reader :pattern, :access, :method
      def initialize(hash)
        super
        @pattern = @hash['pattern']
        @method = @hash['method']
        @access = @hash['access']
      end
    end

    def initialize the_path, the_intercept, the_subject
      @path = the_path
      @intercept = Intercept.new(the_intercept)
      @entry_point = EntryPoint.new(path['entry-point'])
      @security = path['security'] != 'none'
      @decision_manager = path['access-decision-manager'] && path['access-decision-manager']['id']
      @decision_mode = path['access-decision-manager'] && path['access-decision-manager']['class']
      @subject = the_subject
    end

    alias security? security

    # List of "access" used in uaa:
    # ["scope=openid",
    #  "IS_AUTHENTICATED_FULLY",
    #  "IS_AUTHENTICATED_FULLY,scope=clients.secret",
    #  "#oauth2.hasScope('clients.write')",
    #  "#oauth2.hasScope('clients.read')",
    #  "scope=scim.write,scope=groups.update,memberScope=writer",
    #  "scope=scim.read,memberScope=reader",
    #  "scope=scim.write",
    #  "ROLE_NONEXISTENT",
    #  "IS_AUTHENTICATED_FULLY,scope=password.write",
    #  "scope=scim.read,user=self",
    #  "scope=scim.write,user=self",
    #  "hasRole('uaa.resource')",
    #  "isAnonymous() or hasRole('uaa.resource')",
    #  "isFullyAuthenticated()",
    #  "IS_AUTHENTICATED_ANONYMOUSLY",
    #  "denyAll"]
    def authorized?(security_context)
      return true if !security

      votes = []

      if intercept
        logger.debug "Processing intercept: #{intercept.inspect}"
        # Oauth2 scopes
        if intercept.access
          scopes = get_scope_enforcement(intercept.access)
          scopes.each do |scope|
            logger.debug "Checking for scope #{scope.inspect}..."
            unless security_context.token
              logger.debug "    No oauth2 token at all!"
              votes << false
              break
            end
            logger.debug "Token has scopes: #{security_context.token.scopes.inspect}"
            vote = security_context.token.has_scope?(scope)
            logger.debug "    #{vote ? 'got it!' : 'nope!'}"
            votes << vote
          end
        end

        # IS_AUTHENTICATED_FULLY, isFullyAuthenticated
        if requires_full_authentication?(intercept.access)
          vote = security_context.authenticated?
          logger.debug "Requires full authentication. Voting #{vote}"
          votes << vote
        end

        # user=self
        if requires_self?(intercept.access)
          vote = security_context.identity && security_context.identity.guid == subject
          logger.debug "Requires action on self. Voting #{vote} for subject guid: #{subject.inspect}."
          votes << vote
        end

        # hasRole(), ROLE_
        # "role" really means a client authority.
        roles = get_role_enforcement(intercept.access)
        roles.each do |role|
          logger.debug "Checking for role #{role.inspect}..."
          unless security_context.client
            logger.debug "    No client auth at all!"
            votes << false
            break
          end
          logger.debug "Client has authorities: #{security_context.client.authorities_list.inspect}"
          vote = security_context.client.has_authority?(role)
          logger.debug "    #{vote ? 'got it!' : 'nope!'}"
          votes << vote
        end

        # TODO: memberScope

      else
        logger.debug "No intercepts. Path was: #{to_s}"
      end

      # decision time
      logger.debug "Access votes are: #{votes.inspect}"
      case decision_mode
      when nil
        # XXX: Is this right? I'm treating it like MODE_UNANIMOUS.
        # This happens for emptyAuthenticationManager
        logger.debug "Requiring unanimous decision (was nil)"
        return votes.inject{|m, v| m && v}
      when MODE_AFFIRMATIVE
        logger.debug "Using affirmative decision"
        return votes.inject{|m, v| m || v}
      when MODE_UNANIMOUS
        logger.debug "Requiring unanimous decision"
        return votes.inject{|m, v| m && v}
      else
        raise "unknown decision mode: #{decision_mode.inspect}. Path was:\n #{to_s}"
      end

      # TODO: authentication-manager

      logger.debug "Didn't get any decision for path. Defaulting to 403. Path was: #{to_s}"
    end

    def get_scope_enforcement(access)
      access.scan(SCOPE_ENFORCEMENT).flatten.compact
    end

    def get_role_enforcement(access)
      access.scan(ROLE_ENFORCEMENT).flatten.compact
    end

    def requires_full_authentication? access
      access =~ FULL_AUTHENTICATION
    end

    def requires_self? access
      access =~ SELF_ENFORCEMENT
    end

    def to_s
      PP.pp(path, txt='')

      return txt
    end

    def [](key)
      path[key]
    end

    def logger
      ApplicationController.logger
    end

  end
end
