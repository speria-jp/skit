# typed: strict
# frozen_string_literal: true

module Skit
  module JsonSchema
    module Definitions
      # Type alias: Union type of PropertyType-related classes
      PropertyTypes = T.type_alias { T.any(PropertyType, ArrayPropertyType, HashPropertyType, UnionPropertyType) }
    end
  end
end
