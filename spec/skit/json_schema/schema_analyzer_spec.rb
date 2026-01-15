# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Skit::JsonSchema::SchemaAnalyzer, type: :unit do
  let(:config) { Skit::JsonSchema::Config.new(class_name: "User") }

  describe "#analyze" do
    context "with simple object schema" do
      let(:schema) do
        {
          "type" => "object",
          "properties" => {
            "name" => { "type" => "string" },
            "age" => { "type" => "integer" },
            "active" => { "type" => "boolean" }
          },
          "required" => %w[name age]
        }
      end

      it "converts to Struct with correct properties" do
        analyzer = described_class.new(schema, config)
        result = analyzer.analyze

        expect(result.class_name).to eq("User")
        expect(result.properties.length).to eq(3)

        name_prop = result.properties.find { |p| p.name == "name" }
        expect(name_prop.type.to_sorbet_type).to eq("String")
        expect(name_prop.required?).to be(true)

        age_prop = result.properties.find { |p| p.name == "age" }
        expect(age_prop.type.to_sorbet_type).to eq("Integer")
        expect(age_prop.required?).to be(true)

        active_prop = result.properties.find { |p| p.name == "active" }
        expect(active_prop.type.to_sorbet_type).to eq("T.nilable(T::Boolean)")
        expect(active_prop.required?).to be(false)
      end
    end

    context "with nested object schema" do
      let(:schema) do
        {
          "type" => "object",
          "properties" => {
            "name" => { "type" => "string" },
            "address" => {
              "type" => "object",
              "properties" => {
                "street" => { "type" => "string" },
                "city" => { "type" => "string" }
              },
              "required" => ["street"]
            }
          },
          "required" => ["name"]
        }
      end

      it "creates nested struct definitions" do
        analyzer = described_class.new(schema, config)
        result = analyzer.analyze

        expect(result.nested_structs.length).to eq(1)
        nested_struct = result.nested_structs.first
        expect(nested_struct.class_name).to eq("UserAddress")

        street_prop = nested_struct.properties.find { |p| p.name == "street" }
        expect(street_prop.type.to_sorbet_type).to eq("String")
        expect(street_prop.required?).to be(true)

        city_prop = nested_struct.properties.find { |p| p.name == "city" }
        expect(city_prop.type.to_sorbet_type).to eq("T.nilable(String)")
        expect(city_prop.required?).to be(false)
      end
    end

    context "with array schema" do
      let(:schema) do
        {
          "type" => "object",
          "properties" => {
            "tags" => {
              "type" => "array",
              "items" => { "type" => "string" }
            },
            "scores" => {
              "type" => "array",
              "items" => { "type" => "integer" }
            }
          }
        }
      end

      it "converts array types correctly" do
        analyzer = described_class.new(schema, config)
        result = analyzer.analyze

        tags_prop = result.properties.find { |p| p.name == "tags" }
        expect(tags_prop.type.to_sorbet_type).to eq("T.nilable(T::Array[String])")

        scores_prop = result.properties.find { |p| p.name == "scores" }
        expect(scores_prop.type.to_sorbet_type).to eq("T.nilable(T::Array[Integer])")
      end
    end

    context "with string format types" do
      let(:schema) do
        {
          "type" => "object",
          "properties" => {
            "created_at" => { "type" => "string", "format" => "date-time" },
            "birthday" => { "type" => "string", "format" => "date" },
            "meeting_time" => { "type" => "string", "format" => "time" },
            "description" => { "type" => "string" }
          }
        }
      end

      it "converts string formats to appropriate Ruby types" do
        analyzer = described_class.new(schema, config)
        result = analyzer.analyze

        created_at_prop = result.properties.find { |p| p.name == "created_at" }
        expect(created_at_prop.type.to_sorbet_type).to eq("T.nilable(DateTime)")

        birthday_prop = result.properties.find { |p| p.name == "birthday" }
        expect(birthday_prop.type.to_sorbet_type).to eq("T.nilable(Date)")

        meeting_time_prop = result.properties.find { |p| p.name == "meeting_time" }
        expect(meeting_time_prop.type.to_sorbet_type).to eq("T.nilable(Time)")

        description_prop = result.properties.find { |p| p.name == "description" }
        expect(description_prop.type.to_sorbet_type).to eq("T.nilable(String)")
      end
    end

    context "with description and examples" do
      let(:schema) do
        {
          "type" => "object",
          "description" => "A user entity",
          "properties" => {
            "name" => {
              "type" => "string",
              "description" => "User's full name",
              "examples" => ["John Doe", "Jane Smith"]
            }
          }
        }
      end

      it "extracts comments from description and examples" do
        analyzer = described_class.new(schema, config)
        result = analyzer.analyze

        expect(result.description).to eq("A user entity")

        name_prop = result.properties.find { |p| p.name == "name" }
        expect(name_prop.comment).to eq("User's full name\nExamples: John Doe, Jane Smith")
      end
    end

    context "with non-object top-level schema" do
      let(:non_object_schema) do
        { "type" => "string" }
      end

      it "raises error for non-object top-level schema" do
        analyzer = described_class.new(non_object_schema, config)
        expect do
          analyzer.analyze
        end.to raise_error(Skit::Error, "Only object type schemas are supported at the top level")
      end
    end

    context "with object without properties as generic hash" do
      let(:schema) do
        {
          "type" => "object",
          "properties" => {
            "metadata" => { "type" => "object" }
          }
        }
      end

      it "generates hash type" do
        analyzer = described_class.new(schema, config)
        result = analyzer.analyze

        metadata_property = result.properties.find { |p| p.name == "metadata" }
        expect(metadata_property.type.to_sorbet_type).to eq("T.nilable(T::Hash[String, T.untyped])")
      end
    end

    context "with array without items specification" do
      let(:schema) do
        {
          "type" => "object",
          "properties" => {
            "items" => { "type" => "array" }
          }
        }
      end

      it "generates array of T.untyped" do
        analyzer = described_class.new(schema, config)
        result = analyzer.analyze

        items_property = result.properties.find { |p| p.name == "items" }
        expect(items_property.type.to_sorbet_type).to eq("T.nilable(T::Array[T.untyped])")
      end
    end
  end

  describe "$ref support" do
    context "with simple $ref to $defs" do
      let(:schema) do
        {
          "$defs" => {
            "Address" => {
              "type" => "object",
              "properties" => {
                "street" => { "type" => "string" },
                "city" => { "type" => "string" }
              },
              "required" => ["street"]
            }
          },
          "type" => "object",
          "properties" => {
            "name" => { "type" => "string" },
            "address" => { "$ref" => "#/$defs/Address" }
          },
          "required" => ["name"]
        }
      end

      it "resolves $ref and creates proper nested struct" do
        analyzer = described_class.new(schema, config)
        result = analyzer.analyze

        expect(result.properties.length).to eq(2)

        name_prop = result.properties.find { |p| p.name == "name" }
        expect(name_prop.type.to_sorbet_type).to eq("String")
        expect(name_prop.required?).to be(true)

        address_prop = result.properties.find { |p| p.name == "address" }
        expect(address_prop.type.to_sorbet_type).to eq("T.nilable(UserAddress)")
        expect(address_prop.required?).to be(false)

        expect(result.nested_structs.length).to eq(1)
        address_struct = result.nested_structs.first
        expect(address_struct.class_name).to eq("UserAddress")
      end
    end

    context "with circular reference" do
      let(:schema) do
        {
          "$defs" => {
            "Node" => {
              "type" => "object",
              "properties" => {
                "value" => { "type" => "string" },
                "next" => { "$ref" => "#/$defs/Node" }
              }
            }
          },
          "type" => "object",
          "properties" => {
            "root" => { "$ref" => "#/$defs/Node" }
          }
        }
      end

      it "detects and raises error for circular references" do
        analyzer = described_class.new(schema, config)
        expect { analyzer.analyze }.to raise_error(Skit::Error, /Circular reference detected/)
      end
    end

    context "with invalid $ref path" do
      let(:schema) do
        {
          "type" => "object",
          "properties" => {
            "address" => { "$ref" => "#/$defs/NonExistent" }
          }
        }
      end

      it "raises error for unresolvable reference" do
        analyzer = described_class.new(schema, config)
        expect { analyzer.analyze }.to raise_error(Skit::Error, /Cannot resolve reference/)
      end
    end

    context "with external $ref" do
      let(:schema) do
        {
          "type" => "object",
          "properties" => {
            "address" => { "$ref" => "https://example.com/schemas/address.json" }
          }
        }
      end

      it "raises error for external references" do
        analyzer = described_class.new(schema, config)
        expect { analyzer.analyze }.to raise_error(Skit::Error, /External references not yet supported/)
      end
    end
  end

  describe "Union type handling" do
    context "with anyOf basic types" do
      let(:schema) do
        {
          "type" => "object",
          "properties" => {
            "value" => {
              "anyOf" => [
                { "type" => "string" },
                { "type" => "integer" }
              ]
            }
          },
          "required" => ["value"]
        }
      end

      it "generates union type" do
        analyzer = described_class.new(schema, config)
        result = analyzer.analyze

        value_prop = result.properties.find { |p| p.name == "value" }
        expect(value_prop.type).to be_a(Skit::JsonSchema::Definitions::UnionPropertyType)
        expect(value_prop.type.to_sorbet_type).to eq("T.any(String, Integer)")
      end
    end

    context "with null in union" do
      let(:schema) do
        {
          "type" => "object",
          "properties" => {
            "value" => {
              "anyOf" => [
                { "type" => "string" },
                { "type" => "null" }
              ]
            }
          },
          "required" => ["value"]
        }
      end

      it "converts to nullable single type" do
        analyzer = described_class.new(schema, config)
        result = analyzer.analyze

        value_prop = result.properties.find { |p| p.name == "value" }
        expect(value_prop.type).to be_a(Skit::JsonSchema::Definitions::PropertyType)
        expect(value_prop.type.to_sorbet_type).to eq("T.nilable(String)")
      end
    end

    context "with complex object union (unsupported)" do
      let(:schema) do
        {
          "type" => "object",
          "properties" => {
            "data" => {
              "oneOf" => [
                {
                  "type" => "object",
                  "properties" => { "name" => { "type" => "string" } }
                },
                {
                  "type" => "object",
                  "properties" => { "id" => { "type" => "integer" } }
                }
              ]
            }
          },
          "required" => ["data"]
        }
      end

      it "falls back to T.untyped" do
        analyzer = described_class.new(schema, config)
        result = analyzer.analyze

        data_prop = result.properties.find { |p| p.name == "data" }
        expect(data_prop.type).to be_a(Skit::JsonSchema::Definitions::PropertyType)
        expect(data_prop.type.to_sorbet_type).to eq("T.untyped")
      end
    end
  end

  describe "title support" do
    context "with CLI class name specified" do
      let(:schema) do
        {
          "type" => "object",
          "title" => "User Profile",
          "properties" => {
            "name" => { "type" => "string" }
          }
        }
      end

      it "uses CLI class name over title" do
        custom_config = Skit::JsonSchema::Config.new(class_name: "CustomUser")
        analyzer = described_class.new(schema, custom_config)
        result = analyzer.analyze

        expect(result.class_name).to eq("CustomUser")
      end
    end

    context "with title in schema but no CLI class name" do
      let(:schema) do
        {
          "type" => "object",
          "title" => "User Profile",
          "properties" => {
            "name" => { "type" => "string" }
          }
        }
      end

      it "uses title for class name" do
        no_class_name_config = Skit::JsonSchema::Config.new
        analyzer = described_class.new(schema, no_class_name_config)
        result = analyzer.analyze

        expect(result.class_name).to eq("UserProfile")
      end
    end

    context "with no CLI class name or title" do
      let(:schema) do
        {
          "type" => "object",
          "properties" => {
            "name" => { "type" => "string" }
          }
        }
      end

      it "uses default class name" do
        no_class_name_config = Skit::JsonSchema::Config.new
        analyzer = described_class.new(schema, no_class_name_config)
        result = analyzer.analyze

        expect(result.class_name).to eq("GeneratedClass")
      end
    end
  end
end
