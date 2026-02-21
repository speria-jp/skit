# typed: strict
# frozen_string_literal: true

module Skit
  module Serialization
    module Processor
      class Integer < Base
        extend T::Sig

        sig { override.params(type_spec: T.untyped).returns(T::Boolean) }
        def self.handles?(type_spec)
          type_spec == ::Integer
        end

        sig { override.params(value: T.untyped, path: Path).returns(::Integer) }
        def serialize(value, path: Path.new)
          raise SerializeError.new("Expected Integer, got #{value.class}", path: path) unless value.is_a?(::Integer)

          value
        end

        sig { override.params(value: T.untyped, path: Path).returns(::Integer) }
        def deserialize(value, path: Path.new)
          raise DeserializeError.new("Expected Integer, got #{value.class}", path: path) unless value.is_a?(::Integer)

          value
        end
      end
    end
  end
end
