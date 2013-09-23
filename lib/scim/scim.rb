module Aok
  module Scim

    # ActiveRecordQueryBuilder.build_query() takes a filter string as an argument
    # and returns something suitable for passing to ActiveRecord.where()
    # Some example arguments and return values
    #
    # arg: "userName eq \"bjensen\""
    # ret: ["LOWER(username) = LOWER(?)", "bjensen"]
    #
    # arg: "name.familyName co \"O'Malley\""
    # ret: ["LOWER(family_name) LIKE ?", "%o'malley%"]
    #
    # arg: "userName sw \"J\""
    # ret: ["LOWER(username) LIKE ?", "j%"]
    #
    # arg: "title pr"
    # ret: ["title IS NOT NULL"]
    #
    # arg: "meta.lastModified gt \"2011-05-13T04:42:34Z\""
    # ret: ["updated_at > ?", "2011-05-13T04:42:34Z"]
    #
    # arg: "meta.lastModified ge \"2011-05-13T04:42:34Z\""
    # ret: ["updated_at >= ?", "2011-05-13T04:42:34Z"]
    #
    # arg: "meta.lastModified lt \"2011-05-13T04:42:34Z\""
    # ret: ["updated_at < ?", "2011-05-13T04:42:34Z"]
    #
    # arg: "meta.lastModified le \"2011-05-13T04:42:34Z\""
    # ret: ["updated_at <= ?", "2011-05-13T04:42:34Z"]
    #
    # arg: "title pr and userType eq \"Employee\""
    # ret: ["title IS NOT NULL and LOWER(user_type) = ?", "employee"]
    #
    # arg: "userType eq \"Employee\" and (emails co \"example.com\" or emails co \"example.org\")"
    # ret: ["LOWER(user_type) = ? AND (LOWER(email) LIKE ? OR LOWER(email) LIKE ?)", "employee", "%example.com%", "%example.org%"]
    class ActiveRecordQueryBuilder
      # Maps SCIM User schema fields in to their equivalents in the Identity model
      USER_FIELD_MAPPING = {
        'username' => 'username',
        'id' => 'guid',
        'name' => {
          'familyname' => 'family_name',
          'givenname' => 'given_name'
        },
        'emails' => {
          'value' => 'email'
        },
        'meta' => {
          'lastmodified' => 'updated_at'
        }
      }

      class << self
        def build_query(filter)
          tree = SCIM::Query::Filter::Parser.new.parse(filter).tree
          build_query_recurse(tree)
        end

        def build_query_recurse(tree, value_possible=false)
          operator = tree.shift
          case tree.size
          when 0
            if value_possible
              unquote_value(operator)
            else
              field_to_string(operator)
            end
          when 1
            case operator
            when 'pr'
              unless tree.kind_of?(String)
                raise "Expected a field name as the argument to 'pr', not #{tree.inspect}"
              end
              return wrap("#{field_to_string(tree)} IS NOT NULL")
            else
              raise "Don't know how to handle unary operator #{operator.inspect}"
            end
          when 2
            left, right = tree

            # left side could be a field or a subexpression
            left = build_query_recurse(left)

            # right side could be a value or a subexpression
            right = build_query_recurse(right, true)

            sql_operator = operator_to_sql(operator)

            # TODO: return something...

          else
            raise "Only know how to deal with unary and binary operators."
          end
          return query_string
        end

        def field_to_string(field)
          path = field.downcase.split('.')
          map = USER_FIELD_MAPPING
          path.each do |p|
            map = map[p]
          end
          raise unless map.kind_of?(String)
          return map
        rescue
          raise "Couldn't resolve field #{field.inspect} to any property of a User"
        end

        def wrap(txt)
          return "(#{txt})"
        end

        def unquote_value(val)
          # TODO: Safer way to parse this?
          val = JSON.parse(val)
          unless [String, Numeric, TrueClass, FalseClass].include?(val.class)
            raise "Unsupported operand #{val.class.inspect}"
          end
          return val
        end

        # TODO: finish this. The return value for this might need to include the
        # marker for the second operand.
        def operator_to_sql(operator)
          case operator
          when 'eq'
            '='
          when 'co'
            raise "Operator #{operator.inspect} not implemented."
          when 'sw'
            raise "Operator #{operator.inspect} not implemented."
          when 'gt'
            raise "Operator #{operator.inspect} not implemented."
          when 'ge'
            raise "Operator #{operator.inspect} not implemented."
          when 'lt'
            raise "Operator #{operator.inspect} not implemented."
          when 'le'
            raise "Operator #{operator.inspect} not implemented."
          when 'and'
            raise "Operator #{operator.inspect} not implemented."
          when 'or'
            raise "Operator #{operator.inspect} not implemented."
          else
            raise "Operator #{operator.inspect} not implemented."
          end
        end
      end
    end
  end
end
