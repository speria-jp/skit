# typed: strict
# frozen_string_literal: true

module Skit
  module JsonSchema
    module Definitions
      class StructProperty
        extend T::Sig

        sig { returns(String) }
        attr_reader :name

        sig { returns(PropertyTypes) }
        attr_reader :type

        sig { returns(Symbol) }
        attr_reader :mutability

        sig { returns(T.nilable(String)) }
        attr_reader :default_value

        sig { returns(T.nilable(String)) }
        attr_reader :comment

        sig do
          params(
            name: String,
            type: PropertyTypes,
            mutability: Symbol,
            default_value: T.nilable(String),
            comment: T.nilable(String)
          ).void
        end
        def initialize(name:, type:, mutability: :prop, default_value: nil, comment: nil)
          @name = name
          @type = type
          @mutability = T.let(validate_mutability(mutability), Symbol)
          @default_value = default_value
          @comment = comment
        end

        sig { returns(T::Boolean) }
        def required?
          !@type.nullable
        end

        sig { returns(T::Boolean) }
        def optional?
          @type.nullable
        end

        sig { returns(T::Boolean) }
        def immutable?
          @mutability == :const
        end

        sig { returns(T::Boolean) }
        def mutable?
          @mutability == :prop
        end

        private

        sig { params(mutability: Symbol).returns(Symbol) }
        def validate_mutability(mutability)
          unless %i[prop const].include?(mutability)
            raise ArgumentError, "mutability must be :prop or :const, got #{mutability.inspect}"
          end

          mutability
        end
      end
    end
  end
end
