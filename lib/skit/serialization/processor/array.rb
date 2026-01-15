# typed: strict
# frozen_string_literal: true

module Skit
  module Serialization
    module Processor
      class Array < Base
        extend T::Sig

        sig { override.params(type_spec: T.untyped).returns(T::Boolean) }
        def self.handles?(type_spec)
          type_spec.is_a?(T::Types::TypedArray)
        end

        sig { params(type_spec: T.untyped, registry: Registry).void }
        def initialize(type_spec, registry:)
          super
          unless type_spec.is_a?(T::Types::TypedArray)
            raise ArgumentError, "Expected T::Types::TypedArray, got #{type_spec.class}"
          end

          @element_type = T.let(type_spec.type, T.untyped)
        end

        sig { override.params(value: T.untyped).returns(T::Array[T.untyped]) }
        def serialize(value)
          raise TypeMismatchError, "Expected Array, got #{value.class}" unless value.is_a?(::Array)

          value.map do |item|
            processor = @registry.processor_for(@element_type)
            processor.serialize(item)
          end
        end

        sig { override.params(value: T.untyped).returns(T::Array[T.untyped]) }
        def deserialize(value)
          raise DeserializationError, "Expected Array, got #{value.class}" unless value.is_a?(::Array)

          value.map do |item|
            processor = @registry.processor_for(@element_type)
            processor.deserialize(item)
          end
        end
      end
    end
  end
end
