# typed: strict
# frozen_string_literal: true

module Skit
  module Serialization
    module Processor
      class String < Base
        extend T::Sig

        sig { override.params(type_spec: T.untyped).returns(T::Boolean) }
        def self.handles?(type_spec)
          type_spec == ::String
        end

        sig { override.params(value: T.untyped, path: Path).returns(::String) }
        def serialize(value, path: Path.new)
          raise SerializeError.new("Expected String, got #{value.class}", path: path) unless value.is_a?(::String)

          value
        end

        sig { override.params(value: T.untyped, path: Path).returns(::String) }
        def deserialize(value, path: Path.new)
          raise DeserializeError.new("Expected String, got #{value.class}", path: path) unless value.is_a?(::String)

          value
        end
      end
    end
  end
end
