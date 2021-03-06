require 'rom/schema/type'

module ROM
  module SQL
    class Type < ROM::Schema::Type
      # Return a new type marked as a FK
      #
      # @return [SQL::Type]
      #
      # @api public
      def foreign_key
        meta(foreign_key: true)
      end

      # Return a new type marked as qualified
      #
      # @return [SQL::Type]
      #
      # @api public
      def qualified
        meta(qualified: true)
      end

      # Return a new type marked as joined
      #
      # @return [SQL::Type]
      #
      # @api public
      def joined
        meta(joined: true)
      end

      # Return if an attribute was used in a join
      #
      # @return [Boolean]
      #
      # @api public
      def joined?
        meta[:joined].equal?(true)
      end

      # Return if an attribute type is qualified
      #
      # @return [Boolean]
      #
      # @api public
      def qualified?
        meta[:qualified].equal?(true)
      end

      # @api public
      def to_sym
        @_to_sym ||=
          if qualified? && aliased?
            :"#{source.dataset}__#{name}___#{meta[:alias]}"
          elsif qualified?
            :"#{source.dataset}__#{name}"
          elsif aliased?
            :"#{name}___#{meta[:alias]}"
          else
            name
          end
      end

      # @api private
      def sql_literal(ds)
        sql_expr.sql_literal(ds)
      end

      # @api private
      def sql_expr
        Sequel.expr(to_sym)
      end
    end
  end
end
