# typed: strict
# frozen_string_literal: true

require "active_model"
require "active_support/json"

module Skit
  class Attribute < ActiveModel::Type::Value
    extend T::Sig

    sig { params(type_spec: T.any(T.class_of(T::Struct), T::Types::Base)).returns(Attribute) }
    def self.[](type_spec)
      new(type_spec)
    end

    sig { params(type_spec: T.any(T.class_of(T::Struct), T::Types::Base)).void }
    def initialize(type_spec)
      super()
      @type_spec = type_spec
      @processor = T.let(
        Serialization.default_registry.processor_for(type_spec),
        Serialization::Processor::Base
      )
    end

    sig { returns(Serialization::Processor::Base) }
    attr_reader :processor

    # Cast is called when assigning a value to the attribute
    # e.g., record.data = { width: 100, height: 200 }
    sig { params(value: T.untyped).returns(T.untyped) }
    def cast(value)
      return nil if value.nil?

      @processor.deserialize(value)
    end

    # Serialize is called before saving to the database
    # Returns JSON string for storage
    sig { params(value: T.untyped).returns(T.nilable(String)) }
    def serialize(value)
      return nil if value.nil?

      serialized = @processor.serialize(value)
      ActiveSupport::JSON.encode(serialized)
    end

    # Deserialize is called when loading from the database
    # Receives JSON string or Hash (depending on database adapter)
    sig { params(value: T.untyped).returns(T.untyped) }
    def deserialize(value)
      return nil if value.nil?

      data = if value.is_a?(String)
               ActiveSupport::JSON.decode(value)
             else
               value
             end

      @processor.deserialize(data)
    end
  end
end
