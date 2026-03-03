# typed: strict
# frozen_string_literal: true

module Skit
  module JsonSchema
    module Definitions
      # Represents a T::Enum type for code generation
      class EnumType
        extend T::Sig

        sig { returns(String) }
        attr_reader :class_name

        sig { returns(T::Array[T.any(String, Integer, Float)]) }
        attr_reader :values

        sig { returns(T::Boolean) }
        attr_reader :nullable

        sig do
          params(
            class_name: String,
            values: T::Array[T.any(String, Integer, Float)],
            nullable: T::Boolean
          ).void
        end
        def initialize(class_name:, values:, nullable: false)
          @class_name = class_name
          @values = values
          @nullable = nullable
        end

        sig { returns(String) }
        def to_sorbet_type
          nullable ? "T.nilable(#{@class_name})" : @class_name
        end

        sig { returns(EnumType) }
        def with_nullable
          EnumType.new(class_name: @class_name, values: @values, nullable: true)
        end

        # Generate enum member name from value
        sig { params(value: T.any(String, Integer, Float)).returns(String) }
        def self.value_to_member_name(value)
          case value
          when String
            result = NamingUtils.to_pascal_case(value)
            return "Empty" if result.empty?

            result = "Val#{result}" if result.match?(/\A\d/)
            result
          when Integer, Float
            NamingUtils.number_to_name(value)
          end
        end

        # Generate value literal for code generation
        sig { params(value: T.any(String, Integer, Float)).returns(String) }
        def self.value_literal(value)
          case value
          when String
            value.inspect
          when Integer, Float
            value.to_s
          end
        end
      end
    end
  end
end
