# typed: strict
# frozen_string_literal: true

module Skit
  module JsonSchema
    module Definitions
      class ArrayPropertyType
        extend T::Sig

        sig { returns(PropertyTypes) }
        attr_reader :item_type

        sig { returns(T::Boolean) }
        attr_reader :nullable

        sig { params(item_type: PropertyTypes, nullable: T::Boolean).void }
        def initialize(item_type:, nullable: false)
          @item_type = item_type
          @nullable = nullable
        end

        sig { returns(String) }
        def to_sorbet_type
          item_type_str = @item_type.to_sorbet_type
          array_type = "T::Array[#{item_type_str}]"
          nullable ? "T.nilable(#{array_type})" : array_type
        end

        sig { returns(ArrayPropertyType) }
        def with_nullable
          ArrayPropertyType.new(item_type: @item_type, nullable: true)
        end
      end
    end
  end
end
