# typed: strict
# frozen_string_literal: true

require_relative "serialization/errors"
require_relative "serialization/path"
require_relative "serialization/processor/base"
require_relative "serialization/registry"

# Processors
require_relative "serialization/processor/string"
require_relative "serialization/processor/integer"
require_relative "serialization/processor/float"
require_relative "serialization/processor/boolean"
require_relative "serialization/processor/symbol"
require_relative "serialization/processor/date"
require_relative "serialization/processor/time"
require_relative "serialization/processor/struct"
require_relative "serialization/processor/simple_type"
require_relative "serialization/processor/array"
require_relative "serialization/processor/hash"
require_relative "serialization/processor/nilable"
require_relative "serialization/processor/union"
require_relative "serialization/processor/json_schema_const"
require_relative "serialization/processor/enum"

module Skit
  module Serialization
    extend T::Sig

    sig { returns(Registry) }
    def self.default_registry
      @default_registry ||= T.let(build_default_registry, T.nilable(Registry))
      @default_registry
    end

    sig { returns(Registry) }
    def self.build_default_registry
      registry = Registry.new
      # Register processors in order of specificity (most specific first)
      registry.register(Processor::Nilable)
      registry.register(Processor::Union)
      registry.register(Processor::Array)
      registry.register(Processor::Hash)
      registry.register(Processor::JsonSchemaConst)
      registry.register(Processor::Enum)
      registry.register(Processor::Struct)
      registry.register(Processor::SimpleType)
      registry.register(Processor::Date)
      registry.register(Processor::Time)
      registry.register(Processor::String)
      registry.register(Processor::Integer)
      registry.register(Processor::Float)
      registry.register(Processor::Boolean)
      registry.register(Processor::Symbol)
      registry
    end

    private_class_method :build_default_registry
  end
end
