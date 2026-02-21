# typed: strict
# frozen_string_literal: true

module Skit
  module Serialization
    module Processor
      class Boolean < Base
        extend T::Sig

        sig { override.params(type_spec: T.untyped).returns(T::Boolean) }
        def self.handles?(type_spec)
          type_spec == T::Boolean
        end

        sig { override.params(value: T.untyped, path: Path).returns(T::Boolean) }
        def serialize(value, path: Path.new)
          unless value.is_a?(TrueClass) || value.is_a?(FalseClass)
            raise SerializeError.new("Expected TrueClass or FalseClass, got #{value.class}", path: path)
          end

          value
        end

        sig { override.params(value: T.untyped, path: Path).returns(T::Boolean) }
        def deserialize(value, path: Path.new)
          unless value.is_a?(TrueClass) || value.is_a?(FalseClass)
            raise DeserializeError.new("Expected TrueClass or FalseClass, got #{value.class}", path: path)
          end

          value
        end
      end
    end
  end
end
