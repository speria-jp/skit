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

        sig { override.params(value: T.untyped, path: Path).returns(::Float) }
        def serialize(value, path: Path.new)
          raise SerializeError.new("Expected Float, got #{value.class}", path: path) unless value.is_a?(::Float)

          value
        end

        sig { override.params(value: T.untyped, path: Path).returns(::Float) }
        def deserialize(value, path: Path.new)
          case value
          when ::Float
            value
          when ::Integer
            value.to_f
          else
            raise DeserializeError.new("Expected Float or Integer, got #{value.class}", path: path)
          end
        end
      end
    end
  end
end
