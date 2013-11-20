require 'pp'
module UaaSpringSecurityUtils
  class Path

    attr_reader :path, :entry_point, :security

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

    def initialize the_path
      @path = the_path
      @entry_point = EntryPoint.new(path['entry-point'])
      @security = path['security'] != 'none'
    end

    def security?; security; end

    def to_s
      PP.pp(path, txt='')

      return txt
    end

    def [](key)
      path[key]
    end

  end
end
