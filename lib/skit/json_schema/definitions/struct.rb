# typed: strict
# frozen_string_literal: true

module Skit
  module JsonSchema
    module Definitions
      class Struct
        extend T::Sig

        sig { returns(String) }
        attr_reader :class_name

        sig { returns(T::Array[StructProperty]) }
        attr_reader :properties

        sig { returns(T::Array[Struct]) }
        attr_reader :nested_structs

        sig { returns(T.nilable(String)) }
        attr_reader :description

        sig do
          params(
            class_name: String,
            properties: T::Array[StructProperty],
            nested_structs: T::Array[Struct],
            description: T.nilable(String)
          ).void
        end
        def initialize(class_name:, properties: [], nested_structs: [], description: nil)
          @class_name = T.let(validate_class_name(class_name), String)
          @properties = properties
          @nested_structs = nested_structs
          @description = description
        end

        sig { returns(T::Array[String]) }
        def referenced_types
          types = []
          @properties.each do |property|
            types.concat(extract_types_from_property_type(property.type))
          end
          types.uniq
        end

        sig { returns(T::Boolean) }
        def nested_structs?
          !@nested_structs.empty?
        end

        sig { returns(T::Array[StructProperty]) }
        def required_properties
          @properties.select(&:required?)
        end

        sig { returns(T::Array[StructProperty]) }
        def optional_properties
          @properties.select(&:optional?)
        end

        sig { params(property: StructProperty).void }
        def add_property(property)
          @properties << property
        end

        sig { params(nested_struct: Struct).void }
        def add_nested_struct(nested_struct)
          @nested_structs << nested_struct
        end

        private

        sig { params(class_name: String).returns(String) }
        def validate_class_name(class_name)
          unless class_name.match?(/\A[A-Z][a-zA-Z0-9_]*\z/)
            raise ArgumentError,
                  "Invalid class name: #{class_name.inspect}. Must start with uppercase letter " \
                  "and contain only alphanumeric characters and underscores."
          end

          class_name
        end

        sig { params(property_type: PropertyTypes).returns(T::Array[String]) }
        def extract_types_from_property_type(property_type)
          types = []

          case property_type
          when ArrayPropertyType
            types.concat(extract_types_from_property_type(property_type.item_type))
          when HashPropertyType
            types.concat(extract_types_from_property_type(property_type.value_type))
          when UnionPropertyType
            property_type.types.each do |union_type|
              types.concat(extract_types_from_property_type(union_type))
            end
          when PropertyType
            base_type = property_type.base_type
            # Check if it's a custom class (inheriting from T::Struct)
            types << base_type unless %w[String Integer Float T::Boolean DateTime Date Time
                                         T.untyped].include?(base_type)
          else
            T.absurd(property_type)
          end

          types
        end
      end
    end
  end
end
