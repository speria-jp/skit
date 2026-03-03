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

        sig { override.params(value: T.untyped, path: Path).returns(T::Array[T.untyped]) }
        def serialize(value, path: Path.new)
          raise SerializeError.new("Expected Array, got #{value.class}", path: path) unless value.is_a?(::Array)

          value.each_with_index.map do |item, index|
            processor = @registry.processor_for(@element_type)
            processor.serialize(item, path: path.append(index))
          end
        end

        sig { override.params(value: T.untyped, path: Path).returns(T::Array[T.untyped]) }
        def deserialize(value, path: Path.new)
          raise DeserializeError.new("Expected Array, got #{value.class}", path: path) unless value.is_a?(::Array)

          value.each_with_index.map do |item, index|
            processor = @registry.processor_for(@element_type)
            processor.deserialize(item, path: path.append(index))
          end
        end

        sig do
          override.params(
            value: T.untyped,
            path: Path,
            blk: T.proc.params(type_spec: T.untyped, node: T.untyped, path: Path).void
          ).void
        end
        def traverse(value, path: Path.new, &blk)
          super

          return unless value.is_a?(::Array)

          value.each_with_index do |item, index|
            processor = @registry.processor_for(@element_type)
            processor.traverse(item, path: path.append(index), &blk)
          end
        end
      end
    end
  end
end
