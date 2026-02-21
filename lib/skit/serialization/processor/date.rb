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

        sig { override.params(value: T.untyped).returns(::String) }
        def serialize(value)
          raise SerializeError, "Expected Date, got #{value.class}" unless value.is_a?(::Date)

          value.iso8601
        end

        sig { override.params(value: T.untyped).returns(::Date) }
        def deserialize(value)
          case value
          when ::Date
            value
          when ::String
            ::Date.iso8601(value)
          else
            raise DeserializeError, "Expected Date or String, got #{value.class}"
          end
        rescue ArgumentError => e
          raise DeserializeError, "Failed to deserialize Date: #{e.message}"
        end
      end
    end
  end
end
