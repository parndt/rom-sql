module Helpers
  def qualified_attribute(*args)
    ROM::SQL::QualifiedAttribute[*args]
  end

  def assoc_name(*args)
    ROM::SQL::Association::Name[*args]
  end

  def define_schema(name, attrs)
    ROM::SQL::Schema.define(
      name,
      attributes: attrs.map { |key, value| ROM::SQL::Type.new(value.meta(name: key)) }
    )
  end
end
