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

        sig { override.params(value: T.untyped).returns(::String) }
        def serialize(value)
          raise SerializeError, "Expected Time, got #{value.class}" unless value.is_a?(::Time)

          value.iso8601
        end

        sig { override.params(value: T.untyped).returns(::Time) }
        def deserialize(value)
          case value
          when ::Time
            value
          when ::String
            ::Time.iso8601(value)
          else
            raise DeserializeError, "Expected Time or String, got #{value.class}"
          end
        rescue ArgumentError => e
          raise DeserializeError, "Failed to deserialize Time: #{e.message}"
        end
      end
    end
  end
end
