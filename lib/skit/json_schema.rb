# typed: strict
# frozen_string_literal: true

require_relative "json_schema/types/const"
require_relative "json_schema/definitions/property_type"
require_relative "json_schema/definitions/property_types"
require_relative "json_schema/definitions/array_property_type"
require_relative "json_schema/definitions/hash_property_type"
require_relative "json_schema/definitions/union_property_type"
require_relative "json_schema/definitions/struct_property"
require_relative "json_schema/definitions/struct"
require_relative "json_schema/config"
require_relative "json_schema/class_name_path"
require_relative "json_schema/schema_analyzer"
require_relative "json_schema/struct_code_generator"
require_relative "json_schema/cli"

module Skit
  module JsonSchema
    extend T::Sig

    # Generate Sorbet T::Struct code from JSON Schema
    #
    # @param schema [Hash] The JSON Schema hash
    # @param options [Hash] Configuration options
    # @option options [String] :class_name Class name for the root struct (optional)
    # @option options [String] :module_name Module name to wrap the generated struct (optional)
    # @option options [String] :typed_strictness Sorbet typing level ('ignore', 'false', 'true', 'strict', 'strong')
    #
    # @return [String] Generated Ruby/Sorbet code
    #
    # @example Basic usage
    #   schema = { "type" => "object", "properties" => { "name" => { "type" => "string" } } }
    #   code = Skit::JsonSchema.generate(schema, class_name: "User")
    #   puts code
    #
    # @example With all options
    #   code = Skit::JsonSchema.generate(
    #     schema,
    #     class_name: "User",
    #     module_name: "MyModule",
    #     typed_strictness: "strict"
    #   )
    sig do
      params(
        schema: T::Hash[String, T.untyped],
        options: T::Hash[T.any(Symbol, String), T.untyped]
      ).returns(String)
    end
    def self.generate(schema, options = {})
      # Extract and validate options (support both symbol and string keys)
      class_name = T.cast(options[:class_name] || options["class_name"], T.nilable(String))
      module_name = T.cast(options[:module_name] || options["module_name"], T.nilable(String))
      typed_strictness = T.cast(options[:typed_strictness] || options["typed_strictness"],
                                T.nilable(String)) || "strict"

      # Create config with smart defaults
      config = Config.new(
        class_name: class_name,
        module_name: module_name,
        typed_strictness: typed_strictness
      )

      # Analyze schema
      analyzer = SchemaAnalyzer.new(schema, config)
      struct_definition = analyzer.analyze

      # Generate code
      generator = StructCodeGenerator.new(struct_definition, config)
      generator.generate
    end
  end
end
