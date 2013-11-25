module Aok
  module ScopesShoehorn
    include Aok::ModelAuthoritiesMethods
    def has_scope? scope
      scopes.include?(scope)
    end

    def scopes
      s = read_attribute(:scopes)
      parse_list s
    end

    def scopes=(arr)
      val = arr.nil? ? nil : arr.join(',')
      write_attribute(:scopes, val)
    end
  end
end
