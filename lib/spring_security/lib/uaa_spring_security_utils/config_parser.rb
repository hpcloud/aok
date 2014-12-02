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

    # This takes an array of the filepaths you want to parse, in the order
    # they should be applied. Imports will be processed, so in our case we
    # can just import the root spring-servlet.xml file
    def initialize(files)
      self.files = files
      raise "Files list is empty!" if files.empty?
    end

    def node_to_hash node
      hash = Hash[node.attributes.collect do |name, att|
        value = att.value
        if name =~ /-?ref$/
          name = name.sub(/-?ref$/, '')
          value = if BEAN_BLACKLIST.include?(value)
            {value => "OMITTED"}
          else
            bean = @beans[value]
            raise "couldn't resolve bean #{value}" unless bean
            node_to_hash bean
          end
        end
        [name, value]
      end]

      # fix dereference of some beans
      if hash['']
        subhash = hash.delete('')
        if subhash.kind_of? Hash
          hash.merge!(subhash)
        else
          raise "Unexpect hash form #{hash.inspect}" unless hash.keys.empty?
          hash = subhash
        end

      end


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

    def index_beans_in_file(f)
      xml = Nokogiri::XML.parse(File.read f)
      bean_nodes = xml.xpath('//*[@id]')
      bean_nodes.each do |bean_node|
        beans[bean_node['id']] = bean_node
      end
      xml.xpath('//beans:import', NS_DEF).each do |node|
        import_path = File.join(File.dirname(f), node['resource'])
        index_beans_in_file(import_path)
      end
    end

    def parse
      @beans = {}
      files.each do |f|
        index_beans_in_file(f)
      end
      raise "no beans!" if beans.empty?
      @path_rules = []
      files.each do |f|
        import(f)
      end
    end

    def import(f)
      xml = Nokogiri::XML.parse(File.read f)
      xml.xpath('//sec:http | //beans:import', NS_DEF).each do |node|
        case node.name
        when 'import'
          import_path = File.join(File.dirname(f), node['resource'])
          import(import_path)
        when 'http'
          path_rules << node_to_hash(node)
        else
          raise "unexpected node type #{node.name.inspect}"
        end
      end
    end

    def to_yaml
      path_rules.to_yaml
    end


  end
end
