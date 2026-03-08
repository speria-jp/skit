# typed: strict
# frozen_string_literal: true

module Skit
  module JsonSchema
    module Definitions
      # Type alias: Union type of PropertyType-related classes
      PropertyTypes = T.type_alias do
        T.any(PropertyType, ArrayPropertyType, HashPropertyType, UnionPropertyType, ConstType, EnumType,
              TuplePropertyType)
      end
    end
  end
end
