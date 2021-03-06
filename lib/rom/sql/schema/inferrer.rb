require 'dry/core/class_attributes'

module ROM
  module SQL
    class Schema < ROM::Schema
      # @api private
      class Inferrer
        extend Dry::Core::ClassAttributes

        defines :ruby_type_mapping, :numeric_pk_type, :db_type, :db_registry

        ruby_type_mapping(
          integer: Types::Int,
          string: Types::String,
          date: Types::Date,
          datetime: Types::Time,
          boolean: Types::Bool,
          decimal: Types::Decimal,
          float: Types::Float,
          blob: Types::Blob
        ).freeze

        numeric_pk_type Types::Serial

        db_registry Hash.new(self)

        def self.inherited(klass)
          super

          Inferrer.db_registry[klass.db_type] = klass unless klass.name.nil?
        end

        def self.[](type)
          Class.new(self) { db_type(type) }
        end

        def self.get(type)
          db_registry[type]
        end

        # @api private
        def call(source, gateway)
          dataset = source.dataset

          columns = gateway.connection.schema(dataset)
          fks = fks_for(gateway, dataset)

          inferred = columns.map do |(name, definition)|
            type = build_type(definition.merge(foreign_key: fks[name]))

            if type
              type.meta(name: name, source: source)
            end
          end.compact

          [inferred, columns.map(&:first) - inferred.map { |attr| attr.meta[:name] }]
        end

        private

        def build_type(primary_key:, db_type:, type:, allow_null:, foreign_key:, **rest)
          if primary_key
            map_pk_type(type, db_type)
          else
            mapped_type = map_type(type, db_type, rest)

            if mapped_type
              mapped_type = mapped_type.optional if allow_null
              mapped_type = mapped_type.meta(foreign_key: true, target: foreign_key) if foreign_key
              mapped_type
            end
          end
        end

        def map_pk_type(_ruby_type, _db_type)
          self.class.numeric_pk_type.meta(primary_key: true)
        end

        def map_type(ruby_type, db_type, **_kw)
          self.class.ruby_type_mapping[ruby_type]
        end

        # @api private
        def fks_for(gateway, dataset)
          gateway.connection.foreign_key_list(dataset).each_with_object({}) do |definition, fks|
            column, fk = build_fk(definition)

            fks[column] = fk if fk
          end
        end

        def build_fk(columns: , table: , **rest)
          if columns.size == 1
            [columns[0], table]
          else
            # We don't have support for multicolumn foreign keys
            columns[0]
          end
        end
      end
    end
  end
end
