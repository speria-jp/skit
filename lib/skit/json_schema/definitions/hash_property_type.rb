# typed: strict
# frozen_string_literal: true

module Skit
  module JsonSchema
    module Definitions
      class HashPropertyType
        extend T::Sig

        sig { returns(PropertyTypes) }
        attr_reader :value_type

        sig { returns(T::Boolean) }
        attr_reader :nullable

        sig { params(value_type: PropertyTypes, nullable: T::Boolean).void }
        def initialize(value_type:, nullable: false)
          @value_type = value_type
          @nullable = nullable
        end

        sig { returns(String) }
        def to_sorbet_type
          value_type_str = @value_type.to_sorbet_type
          hash_type = "T::Hash[String, #{value_type_str}]"
          nullable ? "T.nilable(#{hash_type})" : hash_type
        end

        sig { returns(HashPropertyType) }
        def with_nullable
          HashPropertyType.new(value_type: @value_type, nullable: true)
        end
      end
    end
  end
end
