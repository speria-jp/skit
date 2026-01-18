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

    context "with const types" do
      let(:const_type) do
        Skit::JsonSchema::Definitions::ConstType.new(
          class_name: "TypeDog",
          value: "dog"
        )
      end

      let(:struct_def) do
        Skit::JsonSchema::Definitions::Struct.new(
          class_name: "Animal",
          properties: [
            Skit::JsonSchema::Definitions::StructProperty.new(
              name: "type",
              type: const_type
            )
          ],
          const_types: [const_type]
        )
      end

      it "generates const class with VALUE constant" do
        generator = described_class.new(struct_def, config)
        result = generator.generate

        expect(result).to include('require "skit"')
        expect(result).to include("class TypeDog < Skit::JsonSchema::Types::Const")
        expect(result).to include('VALUE = "dog"')
      end

      it "generates const class before main struct" do
        generator = described_class.new(struct_def, config)
        result = generator.generate

        const_pos = result.index("class TypeDog")
        struct_pos = result.index("class Animal < T::Struct")
        expect(const_pos).to be < struct_pos
      end

      it "uses const type in struct property" do
        generator = described_class.new(struct_def, config)
        result = generator.generate

        expect(result).to include("prop :type, TypeDog")
      end
    end

    context "with integer const type" do
      let(:const_type) do
        Skit::JsonSchema::Definitions::ConstType.new(
          class_name: "StatusVal200",
          value: 200
        )
      end

      let(:struct_def) do
        Skit::JsonSchema::Definitions::Struct.new(
          class_name: "Response",
          properties: [
            Skit::JsonSchema::Definitions::StructProperty.new(
              name: "status",
              type: const_type
            )
          ],
          const_types: [const_type]
        )
      end

      it "generates const class with integer VALUE" do
        generator = described_class.new(struct_def, config)
        result = generator.generate

        expect(result).to include("class StatusVal200 < Skit::JsonSchema::Types::Const")
        expect(result).to include("VALUE = 200")
      end
    end

    context "with const types in module" do
      let(:module_config) { Skit::JsonSchema::Config.new(module_name: "MyModule", typed_strictness: "strict") }

      let(:const_type) do
        Skit::JsonSchema::Definitions::ConstType.new(
          class_name: "TypeDog",
          value: "dog"
        )
      end

      let(:struct_def) do
        Skit::JsonSchema::Definitions::Struct.new(
          class_name: "Animal",
          properties: [
            Skit::JsonSchema::Definitions::StructProperty.new(
              name: "type",
              type: const_type
            )
          ],
          const_types: [const_type]
        )
      end

      it "wraps const class in module" do
        generator = described_class.new(struct_def, module_config)
        result = generator.generate

        expect(result).to include("module MyModule")
        expect(result).to include("  class TypeDog < Skit::JsonSchema::Types::Const")
        expect(result).to include('    VALUE = "dog"')
      end
    end

    context "with multiple const types" do
      let(:dog_const) do
        Skit::JsonSchema::Definitions::ConstType.new(
          class_name: "TypeDog",
          value: "dog"
        )
      end

      let(:cat_const) do
        Skit::JsonSchema::Definitions::ConstType.new(
          class_name: "TypeCat",
          value: "cat"
        )
      end

      let(:struct_def) do
        Skit::JsonSchema::Definitions::Struct.new(
          class_name: "Animal",
          properties: [],
          const_types: [dog_const, cat_const]
        )
      end

      it "generates all const classes" do
        generator = described_class.new(struct_def, config)
        result = generator.generate

        expect(result).to include("class TypeDog < Skit::JsonSchema::Types::Const")
        expect(result).to include('VALUE = "dog"')
        expect(result).to include("class TypeCat < Skit::JsonSchema::Types::Const")
        expect(result).to include('VALUE = "cat"')
      end
    end
  end
end
