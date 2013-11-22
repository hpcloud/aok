require 'logger'
module UaaSpringSecurityUtils
  class UaaRequestMatcher
    include Util
    attr_accessor :path, :accepts, :method, :parameters, :expected_headers, :mount_point

    def logger= l
      @logger = l
    end

    def logger
      @logger ||= Logger.new('/dev/null')
    end

    def initialize config, logger, mount_point
      self.logger = logger
      if config.kind_of? String
        self.path = config
        return self
      end

      self.mount_point = mount_point

      # else we have the weird hash we got from parsing XML
      self.path = config['constructor-arg']['value']
      properties = arrayize(config['property'])
      properties.each do |property|
        value = property_to_thing(property)
        case property['name']
        when 'headers' then self.expected_headers = value
        when 'accept' then self.accepts = value
        when 'method' then self.method = value
        when 'parameters' then self.parameters = value
        else raise "Unknown property #{property["name"].inspect}"
        end
      end

      return self
    end

    def matches? request
      request_path = request.path.sub(Regexp.new('^' + mount_point + '/?'), '/')
      # message = ''
      # logger.debug do
      #   message = "#{request.request_method.inspect} #{request_path.inspect}.start_with?(#{path.inspect}) with parameters="+
      #     "#{parameters.inspect}, headers #{expected_headers.inspect}, and method #{method.inspect}"
      #   "Checking match of request : " + message
      # end
      return false if !request_path.start_with?(path)

      return false if method && method.upcase != request.request_method.upcase

      (expected_headers || {}).each do |header, expected_value|
        request_value = request.env["HTTP_#{header.upcase.tr('-','_')}"]
        if header.downcase == 'accept'
          return false unless matches_accept_header?
        end
        return false unless matches_header?(request_value, expected_value)
      end

      (parameters || {}).each do |key, expected_value|
        request_value = request[key]
        return false if request_value.nil? || !request_value.start_with?(expected_value)
      end

      # logger.debug "    ...Matched request #{message}"
      return true
    end

    def matches_header? request_value, expected_values
      expected_values ||= []
      return expected_values.all? do |expected_value|
        # logger.debug "Matching header value #{request_value.inspect} against #{expected_value.inspect}"
        !request_value.nil? && request_value.start_with?(expected_value)
      end
    end

    def matches_accept_header?
      return true if request.accept.nil? || request.accept.empty?
      return expected_values.any?{|expected_value| request.accept? expected_value}
    end

    def ==(other)
      other.kind_of? self.class &&
      path == other.path &&
      method == other.method &&
      parameters == other.parameters &&
      accepts == other.accepts &&
      expected_headers == other.expected_headers
    end

    def to_s
      "AOKPath [#{path}#{accepts ? ', ' + accepts : ''}]"
    end

    def property_to_thing(property)
      return property if property.kind_of?(String) || property.nil?
      return property_to_thing(property['value']) if property.key? 'value'
      return property['text'] if property.key? 'text'

      if property.key? 'map'
        thing = {}
        arrayize(property['map']['entry']).each do |entry|
          thing[entry['key']] = property_to_thing(entry)
        end
        return thing
      end

      if property.key? 'list'
        return arrayize(property['list']['value']).collect do |value|
          property_to_thing(value)
        end
      end
      raise "Don't know how to handle property #{property.inspect}"
    end

  end

end
