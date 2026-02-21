# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

module Skit
  class Error < StandardError; end
end

require_relative "skit/version"
# Load JsonSchema::Types::Const early so it can be used by serialization processors
require_relative "skit/json_schema/types/const"
require_relative "skit/serialization"
require_relative "skit/attribute"
require_relative "skit/json_schema"
require_relative "active_model/validations/skit_validator"

module Skit
  extend T::Sig

  # Serialize a T::Struct instance to a Hash with string keys.
  #
  # @param struct [T::Struct] The struct instance to serialize
  # @return [Hash] The serialized Hash
  # @raise [Serialization::SerializeError] If the value is not a T::Struct
  sig { params(struct: T::Struct).returns(T::Hash[::String, T.untyped]) }
  def self.serialize(struct)
    struct_class = struct.class
    raise Serialization::SerializeError, "Expected T::Struct, got #{struct_class}" unless struct_class < T::Struct

    processor = Serialization.default_registry.processor_for(struct_class)
    processor.serialize(struct)
  end

  # Deserialize a Hash to a T::Struct instance.
  #
  # @param hash [Hash] The hash to deserialize
  # @param type [Class] The T::Struct class to deserialize to
  # @return [T::Struct] The deserialized struct instance
  # @raise [Serialization::DeserializeError] If deserialization fails
  sig { params(hash: T.untyped, type: T.class_of(T::Struct)).returns(T::Struct) }
  def self.deserialize(hash, type)
    processor = Serialization.default_registry.processor_for(type)
    processor.deserialize(hash)
  end
end
