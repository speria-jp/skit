# typed: false
# frozen_string_literal: true

# rubocop:disable RSpec/DescribeClass, Security/Eval
require "spec_helper"

RSpec.describe "JSON Schema const support", type: :integration do
  describe "string const" do
    let(:schema) do
      {
        "type" => "object",
        "title" => "Dog",
        "properties" => {
          "type" => { "const" => "dog" },
          "name" => { "type" => "string" },
          "breed" => { "type" => "string" }
        },
        "required" => %w[type name breed]
      }
    end

    it "generates Const class and allows serialization/deserialization" do
      code = Skit::JsonSchema.generate(schema, module_name: "ConstTest1")

      expect(code).to include("class TypeDog < Skit::JsonSchema::Types::Const")
      expect(code).to include('VALUE = "dog"')
      expect(code).to include("prop :type, TypeDog")

      eval(code)

      dog_data = {
        "type" => "dog",
        "name" => "Pochi",
        "breed" => "Shiba"
      }

      dog = Skit.deserialize(dog_data, ConstTest1::Dog)

      expect(dog).to be_a(ConstTest1::Dog)
      expect(dog.type).to be_a(ConstTest1::TypeDog)
      expect(dog.type.value).to eq("dog")
      expect(dog.name).to eq("Pochi")
      expect(dog.breed).to eq("Shiba")

      serialized = Skit.serialize(dog)

      expect(serialized).to eq(dog_data)
    end

    it "raises error when const value does not match" do
      code = Skit::JsonSchema.generate(schema, module_name: "ConstTest2")
      eval(code)

      invalid_data = {
        "type" => "cat",
        "name" => "Tama",
        "breed" => "Persian"
      }

      expect do
        Skit.deserialize(invalid_data, ConstTest2::Dog)
      end.to raise_error(Skit::Serialization::DeserializationError, /Expected "dog", got "cat"/)
    end
  end

  describe "integer const" do
    let(:schema) do
      {
        "type" => "object",
        "title" => "SuccessResponse",
        "properties" => {
          "status" => { "const" => 200 },
          "message" => { "type" => "string" }
        },
        "required" => %w[status message]
      }
    end

    it "generates Const class with integer VALUE" do
      code = Skit::JsonSchema.generate(schema, module_name: "ConstTest3")

      expect(code).to include("class StatusVal200 < Skit::JsonSchema::Types::Const")
      expect(code).to include("VALUE = 200")

      eval(code)

      response_data = {
        "status" => 200,
        "message" => "OK"
      }

      response = Skit.deserialize(response_data, ConstTest3::SuccessResponse)

      expect(response.status).to be_a(ConstTest3::StatusVal200)
      expect(response.status.value).to eq(200)
      expect(response.message).to eq("OK")

      serialized = Skit.serialize(response)

      expect(serialized).to eq(response_data)
    end
  end

  describe "boolean const" do
    let(:schema) do
      {
        "type" => "object",
        "title" => "EnabledFeature",
        "properties" => {
          "enabled" => { "const" => true },
          "name" => { "type" => "string" }
        },
        "required" => %w[enabled name]
      }
    end

    it "generates Const class with boolean VALUE" do
      code = Skit::JsonSchema.generate(schema, module_name: "ConstTest4")

      expect(code).to include("class EnabledTrue < Skit::JsonSchema::Types::Const")
      expect(code).to include("VALUE = true")

      eval(code)

      feature_data = {
        "enabled" => true,
        "name" => "Dark Mode"
      }

      feature = Skit.deserialize(feature_data, ConstTest4::EnabledFeature)

      expect(feature.enabled).to be_a(ConstTest4::EnabledTrue)
      expect(feature.enabled.value).to be(true)
      expect(feature.name).to eq("Dark Mode")

      serialized = Skit.serialize(feature)

      expect(serialized).to eq(feature_data)
    end
  end

  describe "optional const property" do
    let(:schema) do
      {
        "type" => "object",
        "title" => "OptionalConst",
        "properties" => {
          "type" => { "const" => "optional" },
          "value" => { "type" => "string" }
        },
        "required" => ["value"]
      }
    end

    it "handles nil for optional const property" do
      code = Skit::JsonSchema.generate(schema, module_name: "ConstTest5")

      expect(code).to include("prop :type, T.nilable(TypeOptional)")

      eval(code)

      data_without_type = {
        "value" => "test"
      }

      obj = Skit.deserialize(data_without_type, ConstTest5::OptionalConst)

      expect(obj.type).to be_nil
      expect(obj.value).to eq("test")

      serialized = Skit.serialize(obj)

      expect(serialized).to eq({ "type" => nil, "value" => "test" })
    end
  end
end
# rubocop:enable RSpec/DescribeClass, Security/Eval
