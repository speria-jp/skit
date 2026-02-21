# typed: strict
# frozen_string_literal: true

module Skit
  module Serialization
    module Processor
      class Union < Base
        extend T::Sig

        sig { override.params(type_spec: T.untyped).returns(T::Boolean) }
        def self.handles?(type_spec)
          return false unless type_spec.is_a?(T::Types::Union)
          return false if contains_nil_class?(type_spec)
          return false if boolean_union?(type_spec)

          struct_types(type_spec).length == type_spec.types.length
        end

        sig { params(type_spec: T.untyped, registry: Registry).void }
        def initialize(type_spec, registry:)
          super
          @struct_classes = T.let(
            self.class.struct_types(type_spec),
            T::Array[T.class_of(T::Struct)]
          )
        end

        sig { override.params(value: T.untyped).returns(T::Hash[::String, T.untyped]) }
        def serialize(value)
          struct_class = find_struct_class_for_value(value)

          unless struct_class
            raise SerializeError,
                  "#{value.class} is not a member of this union: #{@struct_classes.map(&:name).join(", ")}"
          end

          processor = @registry.processor_for(struct_class)
          processor.serialize(value)
        end

        sig { override.params(value: T.untyped).returns(T.untyped) }
        def deserialize(value)
          return value if value_is_union_member?(value)

          unless value.is_a?(::Hash)
            raise DeserializeError, "Expected Hash or union member struct, got #{value.class}"
          end

          @struct_classes.each do |struct_class|
            result = try_deserialize(value, struct_class)
            return result if result
          end

          raise DeserializeError, "No matching struct found for union: #{@struct_classes.map(&:name).join(", ")}"
        end

        class << self
          extend T::Sig

          sig { params(type_spec: T.untyped).returns(T::Boolean) }
          def contains_nil_class?(type_spec)
            type_spec.types.any? do |t|
              t.is_a?(T::Types::Simple) && t.raw_type == NilClass
            end
          end

          sig { params(type_spec: T.untyped).returns(T::Boolean) }
          def boolean_union?(type_spec)
            raw_types = type_spec.types.filter_map do |t|
              t.is_a?(T::Types::Simple) ? t.raw_type : nil
            end
            raw_types.sort_by { |t| t.name.to_s } == [FalseClass, TrueClass]
          end

          sig { params(type_spec: T.untyped).returns(T::Array[T.class_of(T::Struct)]) }
          def struct_types(type_spec)
            type_spec.types.filter_map do |t|
              next unless t.is_a?(T::Types::Simple)

              klass = t.raw_type
              klass if klass.is_a?(Class) && klass < T::Struct
            end
          end
        end

        private

        sig { params(value: T.untyped).returns(T.nilable(T.class_of(T::Struct))) }
        def find_struct_class_for_value(value)
          @struct_classes.find { |klass| value.is_a?(klass) }
        end

        sig { params(value: T.untyped).returns(T::Boolean) }
        def value_is_union_member?(value)
          @struct_classes.any? { |klass| value.is_a?(klass) }
        end

        sig { params(value: T::Hash[T.untyped, T.untyped], struct_class: T.class_of(T::Struct)).returns(T.nilable(T::Struct)) }
        def try_deserialize(value, struct_class)
          processor = @registry.processor_for(struct_class)
          processor.deserialize(value)
        rescue SerializeError, DeserializeError, ArgumentError, TypeError
          nil
        end
      end
    end
  end
end
