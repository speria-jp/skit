# typed: strict
# frozen_string_literal: true

module Skit
  module Serialization
    module Processor
      # Processor for Skit::JsonSchema::Types::Const subclasses.
      #
      # Serializes to the const VALUE, deserializes by matching the VALUE.
      class JsonSchemaConst < Base
        extend T::Sig

        sig { override.params(type_spec: T.untyped).returns(T::Boolean) }
        def self.handles?(type_spec)
          return false unless type_spec.is_a?(Class)

          !!(type_spec < Skit::JsonSchema::Types::Const)
        end

        sig { params(type_spec: T.untyped, registry: Registry).void }
        def initialize(type_spec, registry:)
          super
          unless type_spec.is_a?(Class) && type_spec < Skit::JsonSchema::Types::Const
            raise ArgumentError, "Expected Skit::JsonSchema::Types::Const subclass, got #{type_spec}"
          end

          @const_class = T.let(type_spec, T.class_of(Skit::JsonSchema::Types::Const))
        end

        sig { override.params(value: T.untyped).returns(T.untyped) }
        def serialize(value)
          raise TypeMismatchError, "Expected #{@const_class}, got #{value.class}" unless value.is_a?(@const_class)

          value.value
        end

        sig { override.params(value: T.untyped).returns(Skit::JsonSchema::Types::Const) }
        def deserialize(value)
          return value if value.is_a?(@const_class)

          expected = @const_class.value

          unless value == expected
            raise DeserializationError,
                  "Expected #{expected.inspect}, got #{value.inspect} for #{@const_class}"
          end

          @const_class.new
        end
      end
    end
  end
end
