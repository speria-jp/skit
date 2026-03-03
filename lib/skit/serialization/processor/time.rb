# typed: strict
# frozen_string_literal: true

require "time"

module Skit
  module Serialization
    module Processor
      class Time < Base
        extend T::Sig

        sig { override.params(type_spec: T.untyped).returns(T::Boolean) }
        def self.handles?(type_spec)
          type_spec == ::Time
        end

        sig { override.params(value: T.untyped, path: Path).returns(::String) }
        def serialize(value, path: Path.new)
          raise SerializeError.new("Expected Time, got #{value.class}", path: path) unless value.is_a?(::Time)

          value.iso8601
        end

        sig { override.params(value: T.untyped, path: Path).returns(::Time) }
        def deserialize(value, path: Path.new)
          case value
          when ::Time
            value
          when ::String
            ::Time.iso8601(value)
          else
            raise DeserializeError.new("Expected Time or String, got #{value.class}", path: path)
          end
        rescue ArgumentError => e
          raise DeserializeError.new("Failed to deserialize Time: #{e.message}", path: path)
        end
      end
    end
  end
end
