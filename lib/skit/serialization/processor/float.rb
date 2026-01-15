# typed: strict
# frozen_string_literal: true

module Skit
  module Serialization
    module Processor
      class Float < Base
        extend T::Sig

        sig { override.params(type_spec: T.untyped).returns(T::Boolean) }
        def self.handles?(type_spec)
          type_spec == ::Float
        end

        sig { override.params(value: T.untyped).returns(::Float) }
        def serialize(value)
          raise TypeMismatchError, "Expected Float, got #{value.class}" unless value.is_a?(::Float)

          value
        end

        sig { override.params(value: T.untyped).returns(::Float) }
        def deserialize(value)
          case value
          when ::Float
            value
          when ::Integer
            value.to_f
          else
            raise DeserializationError, "Expected Float or Integer, got #{value.class}"
          end
        end
      end
    end
  end
end
