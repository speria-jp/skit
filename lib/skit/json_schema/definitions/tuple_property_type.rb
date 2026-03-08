# typed: strict
# frozen_string_literal: true

module Skit
  module JsonSchema
    module Definitions
      class TuplePropertyType
        extend T::Sig

        sig { returns(T::Array[PropertyTypes]) }
        attr_reader :item_types

        sig { returns(T::Boolean) }
        attr_reader :nullable

        sig { params(item_types: T::Array[PropertyTypes], nullable: T::Boolean).void }
        def initialize(item_types:, nullable: false)
          @item_types = item_types
          @nullable = nullable
        end

        sig { returns(String) }
        def to_sorbet_type
          tuple_type = "[#{@item_types.map(&:to_sorbet_type).join(", ")}]"
          nullable ? "T.nilable(#{tuple_type})" : tuple_type
        end

        sig { returns(TuplePropertyType) }
        def with_nullable
          TuplePropertyType.new(item_types: @item_types, nullable: true)
        end
      end
    end
  end
end
