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

        sig { override.params(value: T.untyped, path: Path).returns(::String) }
        def serialize(value, path: Path.new)
          raise SerializeError.new("Expected Symbol, got #{value.class}", path: path) unless value.is_a?(::Symbol)

          value.to_s
        end

        sig { override.params(value: T.untyped, path: Path).returns(::Symbol) }
        def deserialize(value, path: Path.new)
          return value if value.is_a?(::Symbol)

          unless value.is_a?(::String)
            raise DeserializeError.new("Expected String or Symbol, got #{value.class}",
                                       path: path)
          end

          value.to_sym
        end
      end
    end
  end
end
