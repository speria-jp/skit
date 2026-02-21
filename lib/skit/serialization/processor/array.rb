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
          raise SerializeError, "Expected Array, got #{value.class}" unless value.is_a?(::Array)

          value.map do |item|
            processor = @registry.processor_for(@element_type)
            processor.serialize(item)
          end
        end

        sig { override.params(value: T.untyped).returns(T::Array[T.untyped]) }
        def deserialize(value)
          raise DeserializeError, "Expected Array, got #{value.class}" unless value.is_a?(::Array)

          value.map do |item|
            processor = @registry.processor_for(@element_type)
            processor.deserialize(item)
          end
        end

        sig do
          override.params(
            value: T.untyped,
            path: ::String,
            blk: T.proc.params(type_spec: T.untyped, node: T.untyped, path: ::String).void
          ).void
        end
        def traverse(value, path: "", &blk)
          super

          return unless value.is_a?(::Array)

          value.each_with_index do |item, index|
            processor = @registry.processor_for(@element_type)
            item_path = "#{path}[#{index}]"
            processor.traverse(item, path: item_path, &blk)
          end
        end
      end
    end
  end
end
