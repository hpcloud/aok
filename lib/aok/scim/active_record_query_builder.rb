module Aok
  module Scim
    # Instance method `build_query()` takes a filter string as an argument and
    # returns something suitable for passing to `ActiveRecord.where()`. See
    # test/scim-to-arq.rb for examples.
    class ActiveRecordQueryBuilder
      OpMapping = {
        'ge' => '>=',
        'gt' => '>',
        'le' => '<=',
        'lt' => '<',
      }
      # Maps SCIM User schema fields to the Identity model:
      FieldMapping = {
        # XXX Doublecheck these:
        'emails' => 'email',
        'id' => 'guid',
        'meta.lastModified' => 'updated_at',
        'name.familyName' => 'family_name',
        'name.givenName' => 'given_name',
        # XXX should probably be user_name:
        'userName' => 'username',
        'userType' => 'user_type',
      }

      def build_query(filter)
        @rpn = SCIM::Query::Filter::Parser.new.parse(filter).rpn
        finalize eval_expr
      end

      def eval_expr
        if %w(eq co sw pr gt ge lt le and or).include? @rpn.last
          function = @rpn.pop
          if operator = OpMapping[function]
            self.eval_compare(operator)
          else
            self.method("eval_#{function}").call
          end
        else
          @rpn.pop
        end
      end

      def eval_eq
        left, right = binary_args
        ["LOWER(#{left}) = ?", dequote(right).downcase]
      end

      def eval_co
        left, right = binary_args
        ["LOWER(#{left}) LIKE ?", "%#{dequote(right).downcase}%"]
      end

      def eval_sw
        left, right = binary_args
        ["LOWER(#{left}) LIKE ?", "#{dequote(right).downcase}%"]
      end

      def eval_pr
        left = unary_arg
        ["#{left} IS NOT NULL"]
      end

      def eval_compare operator
        left, right = binary_args
        ["#{left} #{operator} ?", "#{dequote(right)}"]
      end

      def eval_and
        left, right = binary_args
        ["(#{left.shift} AND #{right.shift})"].concat(left).concat(right)
      end

      def eval_or
        left, right = binary_args
        ["(#{left.shift} OR #{right.shift})"].concat(left).concat(right)
      end

      def unary_arg
        left = eval_expr
        return FieldMapping[left] || left
      end

      def binary_args
        right = eval_expr
        left = eval_expr
        return FieldMapping[left] || left, right
      end

      def dequote str
        val = JSON.parse(str)
        unless [String, Numeric, TrueClass, FalseClass].any?{|klass| val.kind_of?(klass)}
          raise "Invalid data type for SCIM operand #{val.inspect}"
        end
        return val
      end

      def finalize query
        # Remove any outer parens:
        query[0].sub!(/^\((.*)\)$/, '\1')
        return query
      end
    end
  end
end
