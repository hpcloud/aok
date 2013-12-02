module Aok
  module ModelAuthoritiesMethods
    def inspect
      super.gsub(/(\w*(?:(?:password|secret))\w*: ).*?(?=,)/, '\1REDACTED')
    end

    private
    def parse_list list
      list = list.to_s
      return [] if list.blank?
      return Array(list.split(',')).uniq
    end
  end
end
