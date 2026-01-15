# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Skit::JsonSchema::StructCodeGenerator, type: :unit do
  let(:config) { Skit::JsonSchema::Config.new(typed_strictness: "strict") }

  describe "#generate" do
    context "with simple struct definition" do
      let(:struct_def) do
        Skit::JsonSchema::Definitions::Struct.new(
          class_name: "User",
          properties: [
            Skit::JsonSchema::Definitions::StructProperty.new(
              name: "name",
              type: Skit::JsonSchema::Definitions::PropertyType.new(base_type: "String")
            ),
            Skit::JsonSchema::Definitions::StructProperty.new(
              name: "age",
              type: Skit::JsonSchema::Definitions::PropertyType.new(base_type: "Integer", nullable: true)
            )
          ]
        )
      end

      it "generates valid Ruby code" do
        generator = described_class.new(struct_def, config)
        result = generator.generate

        expect(result).to include("# typed: strict")
        expect(result).to include("# frozen_string_literal: true")
        expect(result).to include("class User < T::Struct")
        expect(result).to include("prop :name, String")
        expect(result).to include("prop :age, T.nilable(Integer)")
        expect(result).to include("end")
      end
    end

    context "with nested struct" do
      let(:nested_struct) do
        Skit::JsonSchema::Definitions::Struct.new(
          class_name: "UserAddress",
          properties: [
            Skit::JsonSchema::Definitions::StructProperty.new(
              name: "city",
              type: Skit::JsonSchema::Definitions::PropertyType.new(base_type: "String")
            )
          ]
        )
      end

      let(:struct_def) do
        Skit::JsonSchema::Definitions::Struct.new(
          class_name: "User",
          properties: [
            Skit::JsonSchema::Definitions::StructProperty.new(
              name: "address",
              type: Skit::JsonSchema::Definitions::PropertyType.new(base_type: "UserAddress")
            )
          ],
          nested_structs: [nested_struct]
        )
      end

      it "generates nested struct before main struct" do
        generator = described_class.new(struct_def, config)
        result = generator.generate

        # Nested struct should appear before main struct
        address_pos = result.index("class UserAddress")
        user_pos = result.index("class User < T::Struct")
        expect(address_pos).to be < user_pos
      end
    end

    context "with module name" do
      let(:module_config) { Skit::JsonSchema::Config.new(module_name: "MyModule", typed_strictness: "strict") }
      let(:struct_def) do
        Skit::JsonSchema::Definitions::Struct.new(
          class_name: "User",
          properties: []
        )
      end

      it "wraps struct in module" do
        generator = described_class.new(struct_def, module_config)
        result = generator.generate

        expect(result).to include("module MyModule")
        expect(result).to include("  class User < T::Struct")
      end
    end

    context "with nested module name" do
      let(:module_config) { Skit::JsonSchema::Config.new(module_name: "Foo::Bar", typed_strictness: "strict") }
      let(:struct_def) do
        Skit::JsonSchema::Definitions::Struct.new(
          class_name: "User",
          properties: []
        )
      end

      it "wraps struct in nested modules" do
        generator = described_class.new(struct_def, module_config)
        result = generator.generate

        expect(result).to include("module Foo")
        expect(result).to include("  module Bar")
        expect(result).to include("    class User < T::Struct")
      end
    end

    context "with property comments" do
      let(:struct_def) do
        Skit::JsonSchema::Definitions::Struct.new(
          class_name: "User",
          properties: [
            Skit::JsonSchema::Definitions::StructProperty.new(
              name: "name",
              type: Skit::JsonSchema::Definitions::PropertyType.new(base_type: "String"),
              comment: "User's full name"
            )
          ]
        )
      end

      it "includes property comments" do
        generator = described_class.new(struct_def, config)
        result = generator.generate

        expect(result).to include("# User's full name")
        expect(result).to include("prop :name, String")
      end
    end

    context "with description" do
      let(:struct_def) do
        Skit::JsonSchema::Definitions::Struct.new(
          class_name: "User",
          properties: [],
          description: "A user entity"
        )
      end

      it "includes class description" do
        generator = described_class.new(struct_def, config)
        result = generator.generate

        expect(result).to include("# A user entity")
        expect(result).to include("class User < T::Struct")
      end
    end
  end
end
