module UaaSpringSecurityUtils
  module Util

    def arrayize possible_nonarray
      case possible_nonarray
      when Array then possible_nonarray
      when nil then []
      else [possible_nonarray]
      end
    end

  end
end
