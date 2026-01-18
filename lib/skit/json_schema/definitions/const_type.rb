# typed: strict
# frozen_string_literal: true

module Skit
  module JsonSchema
    module Definitions
      # Represents a JSON Schema const value type.
      #
      # This generates a Skit::JsonSchema::Types::Const subclass
      # that matches a specific constant value.
      class ConstType
        extend T::Sig

        sig { returns(String) }
        attr_reader :class_name

        sig { returns(T.untyped) }
        attr_reader :value

        sig { returns(T::Boolean) }
        attr_reader :nullable

        sig do
          params(
            class_name: String,
            value: T.untyped,
            nullable: T::Boolean
          ).void
        end
        def initialize(class_name:, value:, nullable: false)
          @class_name = class_name
          @value = value
          @nullable = nullable
        end

        sig { returns(String) }
        def to_sorbet_type
          nullable ? "T.nilable(#{@class_name})" : @class_name
        end

        # Returns the Ruby literal representation of the value
        # rubocop:disable Lint/DuplicateBranch -- Sorbet requires exhaustive case for proper return type
        sig { returns(String) }
        def value_literal
          case @value
          when String
            @value.inspect
          when Integer, Float
            @value.to_s
          when TrueClass
            "true"
          when FalseClass
            "false"
          else
            # This branch should never be reached due to validation in SchemaAnalyzer
            @value.inspect
          end
        end
        # rubocop:enable Lint/DuplicateBranch
      end
    end
  end
end
