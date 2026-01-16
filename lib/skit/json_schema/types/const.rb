# typed: strict
# frozen_string_literal: true

module Skit
  module JsonSchema
    module Types
      # Base class for JSON Schema const values.
      #
      # Subclasses should define a VALUE constant with the const value:
      #
      #   class Dog < Skit::JsonSchema::Types::Const
      #     VALUE = "dog"
      #   end
      #
      # This enables type-safe discriminated unions:
      #
      #   T.any(Dog, Cat)  # "dog" deserializes to Dog, "cat" to Cat
      #
      class Const
        extend T::Sig

        # Returns the const value defined in the subclass.
        sig { returns(T.untyped) }
        def self.value
          # rubocop:disable Sorbet/ConstantsFromStrings
          const_get(:VALUE)
          # rubocop:enable Sorbet/ConstantsFromStrings
        end

        # Returns the const value for this instance.
        sig { returns(T.untyped) }
        def value
          self.class.value
        end

        # Two Const instances are equal if they are of the same class.
        sig { params(other: T.untyped).returns(T::Boolean) }
        def ==(other)
          other.is_a?(self.class)
        end

        # Alias for == to support Hash key comparison.
        sig { params(other: T.untyped).returns(T::Boolean) }
        def eql?(other)
          self == other
        end

        # Hash code based on the class, so all instances of the same class
        # have the same hash code.
        sig { returns(Integer) }
        def hash
          self.class.hash
        end

        # Returns a string representation for debugging.
        sig { returns(String) }
        def inspect
          "#<#{self.class.name} value=#{value.inspect}>"
        end

        # Returns the string representation (the const value as string).
        sig { returns(String) }
        def to_s
          value.to_s
        end
      end
    end
  end
end
