# typed: strict
# frozen_string_literal: true

module Skit
  module Serialization
    module Processor
      class Enum < Base
        extend T::Sig

        sig { override.params(type_spec: T.untyped).returns(T::Boolean) }
        def self.handles?(type_spec)
          return false unless type_spec.is_a?(Class)

          !!(type_spec < T::Enum)
        end

        sig { params(type_spec: T.untyped, registry: Registry).void }
        def initialize(type_spec, registry:)
          super
          unless type_spec.is_a?(Class) && type_spec < T::Enum
            raise ArgumentError, "Expected T::Enum subclass, got #{type_spec}"
          end

          @enum_class = T.let(type_spec, T.class_of(T::Enum))
        end

        sig { override.params(value: T.untyped, path: Path).returns(T.untyped) }
        def serialize(value, path: Path.new)
          unless value.is_a?(@enum_class)
            raise SerializeError.new("Expected #{@enum_class}, got #{value.class}",
                                     path: path)
          end

          value.serialize
        end

        sig { override.params(value: T.untyped, path: Path).returns(T::Enum) }
        def deserialize(value, path: Path.new)
          return value if value.is_a?(@enum_class)

          begin
            @enum_class.deserialize(value)
          rescue KeyError
            valid_values = @enum_class.values.map(&:serialize)
            raise DeserializeError.new(
              "Invalid value #{value.inspect} for #{@enum_class}. Valid values: #{valid_values.inspect}",
              path: path
            )
          end
        end
      end
    end
  end
end
