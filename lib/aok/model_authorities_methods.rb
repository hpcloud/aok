module Aok
  module ModelAuthoritiesMethods
    def authorities_list
      parse_list authorities
    end

    private
    def parse_list list
      list = list.to_s
      return [] if list.blank?
      return Array(list.split(',')).uniq
    end
  end
end