module UaaSpringSecurityUtils
  class PathRules
    include Util
    attr_accessor :path_rules, :mount_point, :logger

    def initialize(rule_filepath, mount_point="/uaa")
      @path_rules = YAML.load_file(rule_filepath)
      sort_intercepts!
      self.mount_point = mount_point
    end

    def match_path request
      request_path = request.path.sub(Regexp.new('^' + mount_point + '/?'), '/')
      method = request.request_method
      path_to_return = nil
      intercept_to_return = nil
      path_rules.each do |path|
        # rules missing 'pattern' attribute should match all requests
        next unless path['pattern'].nil? || simple_match?(request_path, method, path)

        if path['intercept-url'].empty?
          path_to_return = path
        else
          path['intercept-url'].each do |intercept|
            if simple_match?(request_path, method, intercept)
              path_to_return = path
              intercept_to_return = intercept
              break
            end
          end
        end

        request_matcher = get_request_matcher(path['request-matcher'])
        if request_matcher
          if request_matcher.matches?(request)
            return Path.new(path_to_return, intercept_to_return)
          else
            next
          end
        end

        if path_to_return
          return Path.new(path_to_return, intercept_to_return)
        end
      end
      raise "No path matched! Expected a catch-all."
    end

    def unique_values_for_keypath keypath
      keys = keypath.split('/')
      set = path_rules
      while key = keys.shift
        set = set.collect{|item|item.kind_of?(Hash) ? item[key] : item}.uniq
      end
      return set.uniq
    end

    private

    # XXX: fix this to display intercept-url/pattern combinations
    def path_name(path_rule)
        path_rule['pattern'] ||
        path_rule['request-matcher']['constructor-arg']['value'] ||
        path_rule['intercept-url']['pattern']
    end

    def compile_pattern pattern
      re_source = '^' + pattern.gsub('*', '__STAR__').gsub('__STAR____STAR__', '.*?').gsub('__STAR__', '[^/]*?') + '$'
      terminal_slash = /\/\.\*\?\$$/
      re_source.sub!(terminal_slash, '(/.*?)?$') # terminal slashes should be optional
      Regexp.new(re_source, Regexp::IGNORECASE)
    end

    def get_request_matcher config
      return nil if config.nil?
      return nil unless config['class'] =~ /UaaRequestMatcher$/
      return UaaRequestMatcher.new(config, logger, mount_point)
    end

    # a simple match is either an <http> or <intercept-url> element
    # with a 'pattern' attribute and optional 'method'
    def simple_match? request_path, method, pattern_holder
      re = compile_pattern pattern_holder['pattern']
      #logger.debug "Checking match of request : #{method} '#{request_path}' =~ #{pattern_holder['method'] || '*'} #{re.inspect}"
      if request_path =~ re && (pattern_holder['method'].blank? || pattern_holder['method'].upcase == method.upcase)
        #logger.debug "    ...match!"
        return true
      end
      return false
    end

    def sort_intercepts!
      path_rules.each do |rule|
        rule['intercept-url'] = arrayize(rule['intercept-url'])
        rule['intercept-url'].sort!{|a,b| intercept_compare(a,b)}
      end
    end

    # The order in the YAML should be kept, except that intercept-urls with
    # a 'method' sort higher than those without. see url 'note'
    # http://docs.spring.io/spring-security/site/docs/3.1.4.RELEASE/reference/ns-config.html#ns-minimal
    def intercept_compare a, b
      raise a['method'].inspect if a['method'].kind_of?(Hash)
      raise b['method'].inspect if b['method'].kind_of?(Hash)
      case
      when (a['method'].nil? && b['method'].nil?) ||
        (a['method'] && b['method']) then 0
      when a['method'] then -1
      when b['method'] then 1
      end
    end

    def paths
      path_rules.collect{|p|path_name p}
    end

  end
end
