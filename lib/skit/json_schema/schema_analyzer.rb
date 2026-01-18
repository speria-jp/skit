# typed: strict
# frozen_string_literal: true

require "json_schemer"

module Skit
  module JsonSchema
    class SchemaAnalyzer
      extend T::Sig

      sig { params(schema: T::Hash[String, T.untyped], config: Config).void }
      def initialize(schema, config)
        @schema = schema
        @schemer = T.let(JSONSchemer.schema(@schema), T.untyped)
        @nested_structs = T.let({}, T::Hash[String, Definitions::Struct])
        @const_types = T.let({}, T::Hash[String, Definitions::ConstType])
        @enum_types = T.let({}, T::Hash[String, Definitions::EnumType])
        @config = config
        @ref_stack = T.let([], T::Array[String])
      end

      sig { returns(Definitions::Struct) }
      def analyze
        validate_schema

        # Only object type is supported at the top level
        raise Skit::Error, "Only object type schemas are supported at the top level" unless @schema["type"] == "object"

        root_class_name_path = determine_root_class_name
        build_struct(@schema, root_class_name_path)
      end

      private

      sig { returns(ClassNamePath) }
      def determine_root_class_name
        # Determine root class name (in order of priority)
        # 1. Class name specified by CLI option
        # 2. Class name converted from title
        # 3. Default class name
        if (cli_class_name = @config.class_name)
          ClassNamePath.new([cli_class_name])
        elsif (title = extract_title(@schema))
          ClassNamePath.title_to_class_name(title)
        else
          ClassNamePath.default
        end
      end

      sig { params(schema: T::Hash[String, T.untyped]).returns(T.nilable(String)) }
      def extract_title(schema)
        title = schema["title"]
        return nil unless title.is_a?(String) && !title.strip.empty?

        title
      end

      sig { void }
      def validate_schema
        return if @schemer.valid_schema?

        raise Skit::Error, "Invalid JSON Schema"
      end

      sig { params(schema: T::Hash[String, T.untyped], class_name_path: ClassNamePath).returns(Definitions::Struct) }
      def build_struct(schema, class_name_path)
        unless schema["type"] == "object"
          raise ArgumentError,
                "Expected object type schema, got #{schema["type"].inspect}"
        end

        properties = []

        if schema["properties"]
          required_fields = T.cast(schema["required"] || [], T::Array[String])

          schema["properties"].each do |prop_name, prop_schema|
            prop_schema_typed = T.cast(prop_schema, T::Hash[String, T.untyped])

            # Delegate all types to build_property_type (pass class name path for object types)
            property_class_name_path = class_name_path.append(prop_name)
            property_type = build_property_type(prop_schema_typed, property_class_name_path)

            # Make nullable if not required
            is_required = required_fields.include?(prop_name)
            property_type = make_nullable(property_type) unless is_required

            property = Definitions::StructProperty.new(
              name: prop_name,
              type: property_type,
              comment: extract_comment(prop_schema_typed)
            )
            properties << property
          end
        end

        Definitions::Struct.new(
          class_name: class_name_path.to_class_name,
          properties: properties,
          nested_structs: @nested_structs.values,
          const_types: @const_types.values,
          enum_types: @enum_types.values,
          description: schema["description"]
        )
      end

      sig { params(schema: T::Hash[String, T.untyped], class_name_path: ClassNamePath).returns(Definitions::PropertyTypes) }
      def build_property_type(schema, class_name_path)
        # Resolve $ref if present, then process
        if (ref_path = schema["$ref"])
          # Circular reference check
          if @ref_stack.include?(ref_path)
            raise Skit::Error,
                  "Circular reference detected: #{ref_path} -> #{@ref_stack.join(" -> ")}"
          end

          @ref_stack.push(ref_path)
          begin
            resolved_schema = resolve_ref(ref_path)
            result = build_property_type(resolved_schema, class_name_path)
          ensure
            @ref_stack.pop
          end
          return result
        end

        # Const type processing
        return build_const_type(schema, class_name_path) if schema.key?("const")

        # Enum type processing
        return build_enum_type(schema, class_name_path) if schema.key?("enum")

        # Union type processing
        return build_union_type(schema, class_name_path) if schema["anyOf"] || schema["oneOf"]

        case schema["type"]
        when "string"
          build_string_type(schema)
        when "integer"
          Definitions::PropertyType.new(base_type: "Integer")
        when "number"
          Definitions::PropertyType.new(base_type: "Float")
        when "boolean"
          Definitions::PropertyType.new(base_type: "T::Boolean")
        when "array"
          build_array_type(schema, class_name_path)
        when "object"
          build_object_type(schema, class_name_path)
        else
          # Fallback to T.untyped for unsupported types
          Definitions::PropertyType.new(base_type: "T.untyped")
        end
      end

      sig { params(schema: T::Hash[String, T.untyped], class_name_path: ClassNamePath).returns(Definitions::PropertyTypes) }
      def build_object_type(schema, class_name_path)
        if schema["properties"]
          build_object_with_properties(schema, class_name_path)
        else
          # Generic hash when no properties are defined
          untyped_value = Definitions::PropertyType.new(base_type: "T.untyped")
          Definitions::HashPropertyType.new(value_type: untyped_value)
        end
      end

      sig { params(schema: T::Hash[String, T.untyped], class_name_path: ClassNamePath).returns(Definitions::PropertyType) }
      def build_object_with_properties(schema, class_name_path)
        # Use title when specified with priority
        final_class_name_path = if (title = extract_title(schema))
                                  # Use class name generated from title as-is when title is specified
                                  ClassNamePath.title_to_class_name(title)
                                else
                                  class_name_path
                                end

        class_name = final_class_name_path.to_class_name

        unless @nested_structs.key?(class_name)
          struct_def = build_struct(schema, final_class_name_path)
          @nested_structs[class_name] = struct_def
        end

        Definitions::PropertyType.new(base_type: class_name)
      end

      sig { params(schema: T::Hash[String, T.untyped]).returns(Definitions::PropertyType) }
      def build_string_type(schema)
        case schema["format"]
        when "date-time"
          Definitions::PropertyType.new(base_type: "DateTime")
        when "date"
          Definitions::PropertyType.new(base_type: "Date")
        when "time"
          Definitions::PropertyType.new(base_type: "Time")
        else
          Definitions::PropertyType.new(base_type: "String")
        end
      end

      sig { params(schema: T::Hash[String, T.untyped], class_name_path: ClassNamePath).returns(Definitions::ConstType) }
      def build_const_type(schema, class_name_path)
        const_value = schema["const"]

        # Validate const value type (only string, integer, float, boolean are supported)
        unless valid_const_value?(const_value)
          raise Skit::Error, "Unsupported const value type: #{const_value.class}. " \
                             "Only String, Integer, Float, and Boolean are supported."
        end

        # Generate class name from property name and const value
        class_name = generate_const_class_name(class_name_path, const_value)

        const_type = Definitions::ConstType.new(
          class_name: class_name,
          value: const_value
        )

        # Store const type definition (dedup by class name)
        @const_types[class_name] = const_type unless @const_types.key?(class_name)

        const_type
      end

      sig { params(value: T.untyped).returns(T::Boolean) }
      def valid_const_value?(value)
        case value
        when String, Integer, Float, TrueClass, FalseClass
          true
        else
          false
        end
      end

      sig { params(class_name_path: ClassNamePath, const_value: T.untyped).returns(String) }
      def generate_const_class_name(class_name_path, const_value)
        # Generate class name from property name and const value
        # e.g., "type" property with value "dog" -> "TypeDog"
        property_name = class_name_path.property_name

        value_suffix = case const_value
                       when String
                         # Convert string value to PascalCase
                         # "dog" -> "Dog", "my_value" -> "MyValue", "some-thing" -> "SomeThing"
                         const_value.gsub(/[^a-zA-Z0-9]+/, "_")
                                    .split("_")
                                    .map(&:capitalize)
                                    .join
                       when Integer, Float
                         # For numbers, prefix with "Val" to ensure valid class name
                         # 200 -> "Val200", -1 -> "ValMinus1"
                         num_str = const_value.to_s.gsub("-", "Minus").gsub(".", "Dot")
                         "Val#{num_str}"
                       when TrueClass
                         "True"
                       when FalseClass
                         "False"
                       else
                         "Value"
                       end

        "#{property_name}#{value_suffix}"
      end

      sig { params(schema: T::Hash[String, T.untyped], class_name_path: ClassNamePath).returns(Definitions::PropertyTypes) }
      def build_enum_type(schema, class_name_path)
        enum_values = T.cast(schema["enum"], T::Array[T.untyped])

        # Filter and validate enum values
        valid_values = enum_values.select { |v| valid_enum_value?(v) }

        # If no valid values or mixed types that can't be handled, fallback to T.untyped
        return Definitions::PropertyType.new(base_type: "T.untyped") if valid_values.empty?

        # Check if all values are of the same type category (all strings, all numbers, etc.)
        return Definitions::PropertyType.new(base_type: "T.untyped") unless homogeneous_enum_values?(valid_values)

        # Generate class name from property name
        class_name = class_name_path.property_name

        enum_type = Definitions::EnumType.new(
          class_name: class_name,
          values: valid_values
        )

        # Store enum type definition (dedup by class name)
        @enum_types[class_name] = enum_type unless @enum_types.key?(class_name)

        enum_type
      end

      sig { params(value: T.untyped).returns(T::Boolean) }
      def valid_enum_value?(value)
        case value
        when String, Integer, Float
          true
        else
          false
        end
      end

      sig { params(values: T::Array[T.untyped]).returns(T::Boolean) }
      def homogeneous_enum_values?(values)
        return true if values.empty?

        first_type = value_type_category(values.first)
        values.all? { |v| value_type_category(v) == first_type }
      end

      sig { params(value: T.untyped).returns(Symbol) }
      def value_type_category(value)
        case value
        when String
          :string
        when Integer, Float
          :number
        else
          :other
        end
      end

      sig { params(schema: T::Hash[String, T.untyped], class_name_path: ClassNamePath).returns(Definitions::ArrayPropertyType) }
      def build_array_type(schema, class_name_path)
        if schema["items"]
          item_schema = T.cast(schema["items"], T::Hash[String, T.untyped])
          item_type = build_property_type(item_schema, class_name_path.append("item"))
          Definitions::ArrayPropertyType.new(item_type: item_type)
        else
          # Array of T.untyped when items is not specified
          untyped_item = Definitions::PropertyType.new(base_type: "T.untyped")
          Definitions::ArrayPropertyType.new(item_type: untyped_item)
        end
      end

      sig { params(schema: T::Hash[String, T.untyped], class_name_path: ClassNamePath).returns(Definitions::PropertyTypes) }
      def build_union_type(schema, class_name_path)
        union_schemas = T.cast(schema["anyOf"] || schema["oneOf"], T::Array[T.untyped])

        # Handle null types: exclude null and make nullable at the end
        has_null = T.let(false, T::Boolean)
        non_null_schemas = T.let([], T::Array[T::Hash[String, T.untyped]])

        union_schemas.each do |union_schema|
          union_schema_typed = T.cast(union_schema, T::Hash[String, T.untyped])
          if union_schema_typed["type"] == "null"
            has_null = true
          else
            non_null_schemas << union_schema_typed
          end
        end

        # Error if no non-null schemas exist
        raise Skit::Error, "Union type with only null is not supported" if non_null_schemas.empty?

        # Return nullable type when single type includes null
        if non_null_schemas.length == 1
          single_schema = T.must(non_null_schemas.first)
          single_type = build_property_type(single_schema, class_name_path)
          return has_null ? make_nullable(single_type) : single_type
        end

        # Analyze multiple types with unique class names for each member
        types = non_null_schemas.each_with_index.map do |union_schema, index|
          build_property_type(union_schema, class_name_path.append("Variant#{index}"))
        end

        union_type = Definitions::UnionPropertyType.new(types: types)
        has_null ? make_nullable(union_type) : union_type
      end

      sig { params(property_type: Definitions::PropertyTypes).returns(Definitions::PropertyTypes) }
      def make_nullable(property_type)
        case property_type
        when Definitions::ArrayPropertyType
          Definitions::ArrayPropertyType.new(item_type: property_type.item_type, nullable: true)
        when Definitions::HashPropertyType
          Definitions::HashPropertyType.new(value_type: property_type.value_type, nullable: true)
        when Definitions::UnionPropertyType
          Definitions::UnionPropertyType.new(types: property_type.types, nullable: true)
        when Definitions::ConstType
          Definitions::ConstType.new(
            class_name: property_type.class_name,
            value: property_type.value,
            nullable: true
          )
        when Definitions::EnumType
          Definitions::EnumType.new(
            class_name: property_type.class_name,
            values: property_type.values,
            nullable: true
          )
        when Definitions::PropertyType
          Definitions::PropertyType.new(
            base_type: property_type.base_type,
            nullable: true
          )
        else
          T.absurd(property_type)
        end
      end

      sig { params(schema: T::Hash[String, T.untyped]).returns(T.nilable(String)) }
      def extract_comment(schema)
        description = schema["description"]
        examples = schema["examples"]

        comment_parts = []
        comment_parts << description if description
        comment_parts << "Examples: #{examples.join(", ")}" if examples&.any?

        comment_parts.empty? ? nil : comment_parts.join("\n")
      end

      sig { params(ref_path: String).returns(T::Hash[String, T.untyped]) }
      def resolve_ref(ref_path)
        # External references are not supported
        raise Skit::Error, "External references not yet supported: #{ref_path}" unless ref_path.start_with?("#/")

        # Parse JSON pointer and resolve reference
        # #/$defs/Name -> ["$defs", "Name"]
        path_parts = T.must(ref_path[2..]).split("/")

        resolved = path_parts.reduce(@schema) do |current, part|
          break nil unless current.is_a?(Hash)

          current[part]
        end

        raise Skit::Error, "Cannot resolve reference: #{ref_path}" unless resolved

        unless resolved.is_a?(Hash)
          raise Skit::Error,
                "Invalid reference target: #{ref_path} - expected object, got #{resolved.class}"
        end

        resolved
      end
    end
  end
end
