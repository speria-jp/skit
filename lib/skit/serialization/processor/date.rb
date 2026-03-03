# typed: strict
# frozen_string_literal: true

require "date"

module Skit
  module Serialization
    module Processor
      class Date < Base
        extend T::Sig

        sig { override.params(type_spec: T.untyped).returns(T::Boolean) }
        def self.handles?(type_spec)
          type_spec == ::Date
        end

        sig { override.params(value: T.untyped, path: Path).returns(::String) }
        def serialize(value, path: Path.new)
          raise SerializeError.new("Expected Date, got #{value.class}", path: path) unless value.is_a?(::Date)

          value.iso8601
        end

        sig { override.params(value: T.untyped, path: Path).returns(::Date) }
        def deserialize(value, path: Path.new)
          case value
          when ::Date
            value
          when ::String
            ::Date.iso8601(value)
          else
            raise DeserializeError.new("Expected Date or String, got #{value.class}", path: path)
          end
        rescue ArgumentError => e
          raise DeserializeError.new("Failed to deserialize Date: #{e.message}", path: path)
        end
      end
    end
  end
end
