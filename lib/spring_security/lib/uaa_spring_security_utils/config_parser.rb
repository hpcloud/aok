module UaaSpringSecurityUtils
  class ConfigParser
    NS_DEF = {
      'sec' => 'http://www.springframework.org/schema/security',
      'beans' => 'http://www.springframework.org/schema/beans',
      'oauth' => 'http://www.springframework.org/schema/security/oauth2'
    }

    # Bean ids we don't care about and don't want in the YAML
    BEAN_BLACKLIST = %W{
      dataSource
    }
      # jdbcTemplate
      # jdbcClientDetailsService

    attr_accessor :beans, :path_rules, :logger, :files

    def initialize(glob_pattern="/s/code/uaa/uaa/src/main/webapp/**/*.xml")
      self.files = Dir.glob(glob_pattern)
      raise "Files list is empty!" if files.empty?
    end

    def node_to_hash node
      hash = Hash[node.attributes.collect do |name, att|
        value = att.value
        if name =~ /-?ref$/
          name = name.sub(/-ref$/, '')
          value = if BEAN_BLACKLIST.include?(value)
            "#{value.inspect} OMITTED"
          else
            bean = @beans[value]
            raise "couldn't resolve bean #{value}" unless bean
            node_to_hash bean
          end
        end
        [name, value]
      end]

      node.children.each do |child|
        value = if child.name == 'text'
          # there are a lot of ignorable text nodes that are just whitespace
          # between tags
          next if child.content =~ /\A\s*\z/
          child.content
        else
          node_to_hash(child)
        end
        if hash.key?(child.name) && !hash[child.name].kind_of?(Array)
          hash[child.name] = [hash[child.name]]
        end
        if hash[child.name].kind_of?(Array)
          hash[child.name] << value
        else
          hash[child.name] = value
        end
      end

      return hash
    end

    def index_beans
      @beans = {}
      files.each do |f|
        xml = Nokogiri::XML.parse(File.read f)
        bean_nodes = xml.xpath('//*[@id]')
        bean_nodes.each do |bean_node|
          beans[bean_node['id']] = bean_node
        end
      end
    end

    def parse
      index_beans
      raise "no beans!" if beans.empty?
      @path_rules = []
      files.each do |f|
        xml = Nokogiri::XML.parse(File.read f)
        # xml.xpath('//sec:http', NS_DEF).each do |node|
        xml.xpath('//sec:http', NS_DEF).each do |node|
          path_rules << node_to_hash(node)
        end
      end
    end

    def to_yaml
      path_rules.to_yaml
    end


  end
end
