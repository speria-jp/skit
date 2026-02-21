# typed: strict
# frozen_string_literal: true

module Skit
  module JsonSchema
    module Definitions
      class UnionPropertyType
        extend T::Sig

        sig { returns(T::Array[PropertyTypes]) }
        attr_reader :types

        sig { returns(T::Boolean) }
        attr_reader :nullable

        sig do
          params(
            types: T::Array[PropertyTypes],
            nullable: T::Boolean
          ).void
        end
        def initialize(types:, nullable: false)
          @types = types
          @nullable = nullable
        end

        sig { returns(String) }
        def to_sorbet_type
          union_str = "T.any(#{@types.map(&:to_sorbet_type).join(", ")})"
          @nullable ? "T.nilable(#{union_str})" : union_str
        end

        sig { returns(UnionPropertyType) }
        def with_nullable
          UnionPropertyType.new(types: @types, nullable: true)
        end
      end
    end
  end
end
