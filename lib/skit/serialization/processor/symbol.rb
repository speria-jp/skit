# typed: strict
# frozen_string_literal: true

module Skit
  module Serialization
    module Processor
      class Symbol < Base
        extend T::Sig

        sig { override.params(type_spec: T.untyped).returns(T::Boolean) }
        def self.handles?(type_spec)
          type_spec == ::Symbol
        end

        sig { override.params(value: T.untyped).returns(::String) }
        def serialize(value)
          raise SerializeError, "Expected Symbol, got #{value.class}" unless value.is_a?(::Symbol)

          value.to_s
        end

        sig { override.params(value: T.untyped).returns(::Symbol) }
        def deserialize(value)
          return value if value.is_a?(::Symbol)

          raise DeserializeError, "Expected String or Symbol, got #{value.class}" unless value.is_a?(::String)

          value.to_sym
        end
      end
    end
  end
end
