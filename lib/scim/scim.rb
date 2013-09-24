require 'scim/query/filter/parser'

module Aok
  module Scim

    # ActiveRecordQueryBuilder.build_query() takes a filter string as an
    # argument and returns something suitable for passing to
    # ActiveRecord.where().
    class ActiveRecordQueryBuilder
      OpMapping = {
        'ge' => '>=',
        'gt' => '>',
        'le' => '<=',
        'lt' => '<',
      }
      # Maps SCIM User schema fields to the Identity model
      FieldMapping = {
        'emails' => 'email',
        'id' => 'guid',
        'meta.lastModified' => 'updated_at',
        'name.familyName' => 'family_name',
        'name.givenName' => 'given_name',
        'userName' => 'username',
      }

      def build_query(filter)
        @rpn = SCIM::Query::Filter::Parser.new.parse(filter).rpn
        @query = ['']
        eval_expr
      end

      def eval_expr
        if %w(eq co sw pr gt ge lt le and or).include? @rpn.last
          op = @rpn.pop
          if operator = OpMapping[op]
            expr = self.method("eval_compare").call(operator)
          else
            expr = self.method("eval_#{op}").call
          end
          @query[0] += ' ' if @query[0] != ''
          @query[0] += expr.shift
          @query.concat expr
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

      def unary_arg
        left = eval_expr
        FieldMapping[left] || left
      end

      def binary_args
        right = eval_expr
        left = eval_expr
        left = FieldMapping[left] || left
        return left, right
      end

      def dequote str
        str =~ /^"(.*)"$/ or
          fail 'String not quoted: '#{str}'"
        return $1
      end
    end
  end
end
