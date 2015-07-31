require 'scim/query/filter/parser'

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
        'emails' => 'email',
        'id' => 'guid',
        'meta.lastmodified' => 'updated_at',
        'name.familyname' => 'family_name',
        'name.givenname' => 'given_name',
        'username' => 'username',
        'usertype' => 'user_type',
        'displayname' => 'name',
      }
      # Filter boolean expressions
      BooleanExpressions = ['or', 'and']

      def build_query(filter, opts = {})
        # Parse the filter into a RPN stack
        @rpn = SCIM::Query::Filter::Parser.new.parse(filter).rpn

        # Check if restricted fields are provided and ensure only these are set.
        valid_fields = []
        if opts[:allowed_ops]
          valid_fields.push(*opts[:allowed_ops])
        end
        if opts[:allowed_fields]
          valid_fields.push(*opts[:allowed_fields])
        end

        if valid_fields.length > 0
          valid_fields.push(*BooleanExpressions)
          @rpn.each do |field|
            if !field.start_with?('"') && !valid_fields.include?(field)
              raise Aok::Errors::ScimFilterError.new("Filter list includes a field/op '#{field}' not in the allowed list")
            end
          end
        end


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
        val = JSON.parse("[#{str}]")[0]
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
