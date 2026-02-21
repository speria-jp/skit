# typed: strict
# frozen_string_literal: true

module Skit
  module Serialization
    module Processor
      class Hash < Base
        extend T::Sig

        sig { override.params(type_spec: T.untyped).returns(T::Boolean) }
        def self.handles?(type_spec)
          type_spec.is_a?(T::Types::TypedHash)
        end

        sig { params(type_spec: T.untyped, registry: Registry).void }
        def initialize(type_spec, registry:)
          super
          unless type_spec.is_a?(T::Types::TypedHash)
            raise ArgumentError, "Expected T::Types::TypedHash, got #{type_spec.class}"
          end

          @key_type = T.let(extract_raw_key_type(type_spec.keys), T.untyped)
          @value_type = T.let(type_spec.values, T.untyped)
        end

        sig { override.params(value: T.untyped, path: Path).returns(T::Hash[::String, T.untyped]) }
        def serialize(value, path: Path.new)
          raise SerializeError.new("Expected Hash, got #{value.class}", path: path) unless value.is_a?(::Hash)

          result = T.let({}, T::Hash[::String, T.untyped])
          value.each do |key, item|
            processor = @registry.processor_for(@value_type)
            result[key.to_s] = processor.serialize(item, path: path.append(key.to_s))
          end
          result
        end

        sig { override.params(value: T.untyped, path: Path).returns(T::Hash[T.untyped, T.untyped]) }
        def deserialize(value, path: Path.new)
          raise DeserializeError.new("Expected Hash, got #{value.class}", path: path) unless value.is_a?(::Hash)

          result = T.let({}, T::Hash[T.untyped, T.untyped])
          value.each do |key, item|
            normalized_key = normalize_key(key)
            processor = @registry.processor_for(@value_type)
            result[normalized_key] = processor.deserialize(item, path: path.append(key.to_s))
          end
          result
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

          return unless value.is_a?(::Hash)

          value.each do |key, val|
            processor = @registry.processor_for(@value_type)
            processor.traverse(val, path: path.append(key.to_s), &blk)
          end
        end

        private

        sig { params(key_type: T.untyped).returns(T.untyped) }
        def extract_raw_key_type(key_type)
          if key_type.is_a?(T::Types::Simple)
            key_type.raw_type
          else
            key_type
          end
        end

        sig { params(key: T.untyped).returns(T.untyped) }
        def normalize_key(key)
          if @key_type == ::String
            key.to_s
          elsif @key_type == ::Symbol
            key.to_sym
          else
            key
          end
        end
      end
    end
  end
end
