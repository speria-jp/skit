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

        # Generate enum member name from value
        sig { params(value: T.any(String, Integer, Float)).returns(String) }
        def self.value_to_member_name(value)
          case value
          when String
            # Convert string value to PascalCase
            # "active" -> "Active", "my_status" -> "MyStatus", "foo-bar" -> "FooBar"
            normalized = value.gsub(/[^a-zA-Z0-9]+/, "_")
                              .gsub(/^_+|_+$/, "")
            return "Empty" if normalized.empty?

            normalized.split("_").map(&:capitalize).join
          when Integer
            # For integers, prefix with "Val" to ensure valid constant name
            # 1 -> "Val1", -5 -> "ValMinus5"
            num_str = value.to_s.gsub("-", "Minus")
            "Val#{num_str}"
          when Float
            # For floats, prefix with "Val" and handle decimal point
            # 1.5 -> "Val1Dot5", -2.5 -> "ValMinus2Dot5"
            num_str = value.to_s.gsub("-", "Minus").gsub(".", "Dot")
            "Val#{num_str}"
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
