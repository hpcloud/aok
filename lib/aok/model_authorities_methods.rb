module Aok
  module ModelAuthoritiesMethods
    private
    def parse_list list
      list = list.to_s
      return [] if list.blank?
      return Array(list.split(',')).uniq
    end
  end
end
