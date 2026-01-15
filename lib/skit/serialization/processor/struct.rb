# typed: strict
# frozen_string_literal: true

module Skit
  module Serialization
    module Processor
      class Struct < Base
        extend T::Sig

        sig { override.params(type_spec: T.untyped).returns(T::Boolean) }
        def self.handles?(type_spec)
          return false unless type_spec.is_a?(Class)

          !!(type_spec < T::Struct)
        end

        sig { params(type_spec: T.untyped, registry: Registry).void }
        def initialize(type_spec, registry:)
          super
          unless type_spec.is_a?(Class) && type_spec < T::Struct
            raise ArgumentError, "Expected T::Struct, got #{type_spec}"
          end

          @struct_class = T.let(type_spec, T.class_of(T::Struct))
        end

        sig { override.params(value: T.untyped).returns(T::Hash[::String, T.untyped]) }
        def serialize(value)
          raise TypeMismatchError, "Expected #{@struct_class}, got #{value.class}" unless value.is_a?(@struct_class)

          @struct_class.props.each_with_object({}) do |(name, prop_def), hash|
            prop_value = value.public_send(name)
            prop_type = prop_def[:type_object]
            processor = @registry.processor_for(prop_type)
            hash[name.to_s] = processor.serialize(prop_value)
          end
        end

        sig { override.params(value: T.untyped).returns(T::Struct) }
        def deserialize(value)
          return value if value.is_a?(@struct_class)

          raise DeserializationError, "Expected Hash, got #{value.class}" unless value.is_a?(::Hash)

          symbolized = value.transform_keys(&:to_sym)

          deserialized = @struct_class.props.each_with_object({}) do |(name, prop_def), hash|
            next unless symbolized.key?(name)

            prop_value = symbolized[name]
            prop_type = prop_def[:type_object]
            processor = @registry.processor_for(prop_type)
            hash[name] = processor.deserialize(prop_value)
          end

          @struct_class.new(**deserialized)
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

          return unless value.is_a?(@struct_class)

          @struct_class.props.each do |name, prop_def|
            prop_value = value.public_send(name)
            prop_type = prop_def[:type_object]
            processor = @registry.processor_for(prop_type)
            prop_path = path.empty? ? name.to_s : "#{path}.#{name}"
            processor.traverse(prop_value, path: prop_path, &blk)
          end
        end
      end
    end
  end
end
