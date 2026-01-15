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

        sig { override.params(value: T.untyped).returns(::Integer) }
        def serialize(value)
          raise TypeMismatchError, "Expected Integer, got #{value.class}" unless value.is_a?(::Integer)

          value
        end

        sig { override.params(value: T.untyped).returns(::Integer) }
        def deserialize(value)
          raise DeserializationError, "Expected Integer, got #{value.class}" unless value.is_a?(::Integer)

          value
        end
      end
    end
  end
end
