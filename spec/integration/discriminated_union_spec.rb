# typed: false
# frozen_string_literal: true

# rubocop:disable RSpec/DescribeClass, Lint/ConstantDefinitionInBlock
# rubocop:disable RSpec/BeforeAfterAll, RSpec/LeakyConstantDeclaration
require "spec_helper"

RSpec.describe "Discriminated union with const", type: :integration do
  # These tests verify that:
  # 1. Code generation produces T.any(...) for oneOf with objects
  # 2. The serialization layer correctly handles discriminated unions

  describe "discriminated union as struct property" do
    before(:all) do
      # Manually define the classes that would be generated for a discriminated union
      module DiscriminatedUnionTest
        class TypeDog < Skit::JsonSchema::Types::Const
          VALUE = "dog"
        end

        class TypeCat < Skit::JsonSchema::Types::Const
          VALUE = "cat"
        end

        class Dog < T::Struct
          prop :type, TypeDog
          prop :name, String
          prop :breed, String
        end

        class Cat < T::Struct
          prop :type, TypeCat
          prop :name, String
          prop :color, String
        end

        # Container struct with discriminated union property
        class AnimalContainer < T::Struct
          prop :id, Integer
          prop :animal, T.any(Dog, Cat)
        end
      end
    end

    it "deserializes to Dog when animal type is 'dog'" do
      container_data = {
        "id" => 1,
        "animal" => {
          "type" => "dog",
          "name" => "Pochi",
          "breed" => "Shiba"
        }
      }

      result = Skit.deserialize(container_data, DiscriminatedUnionTest::AnimalContainer)

      expect(result).to be_a(DiscriminatedUnionTest::AnimalContainer)
      expect(result.id).to eq(1)
      expect(result.animal).to be_a(DiscriminatedUnionTest::Dog)
      expect(result.animal.type).to be_a(DiscriminatedUnionTest::TypeDog)
      expect(result.animal.type.value).to eq("dog")
      expect(result.animal.name).to eq("Pochi")
      expect(result.animal.breed).to eq("Shiba")
    end

    it "deserializes to Cat when animal type is 'cat'" do
      container_data = {
        "id" => 2,
        "animal" => {
          "type" => "cat",
          "name" => "Tama",
          "color" => "white"
        }
      }

      result = Skit.deserialize(container_data, DiscriminatedUnionTest::AnimalContainer)

      expect(result).to be_a(DiscriminatedUnionTest::AnimalContainer)
      expect(result.id).to eq(2)
      expect(result.animal).to be_a(DiscriminatedUnionTest::Cat)
      expect(result.animal.type).to be_a(DiscriminatedUnionTest::TypeCat)
      expect(result.animal.type.value).to eq("cat")
      expect(result.animal.name).to eq("Tama")
      expect(result.animal.color).to eq("white")
    end

    it "raises error when animal type value is invalid" do
      invalid_data = {
        "id" => 3,
        "animal" => {
          "type" => "bird",
          "name" => "Piyo"
        }
      }

      expect do
        Skit.deserialize(invalid_data, DiscriminatedUnionTest::AnimalContainer)
      end.to raise_error(Skit::Serialization::DeserializationError, /No matching struct found/)
    end

    it "serializes container with Dog correctly" do
      container = DiscriminatedUnionTest::AnimalContainer.new(
        id: 1,
        animal: DiscriminatedUnionTest::Dog.new(
          type: DiscriminatedUnionTest::TypeDog.new,
          name: "Pochi",
          breed: "Shiba"
        )
      )

      result = Skit.serialize(container)

      expect(result).to eq({
                             "id" => 1,
                             "animal" => {
                               "type" => "dog",
                               "name" => "Pochi",
                               "breed" => "Shiba"
                             }
                           })
    end

    it "serializes container with Cat correctly" do
      container = DiscriminatedUnionTest::AnimalContainer.new(
        id: 2,
        animal: DiscriminatedUnionTest::Cat.new(
          type: DiscriminatedUnionTest::TypeCat.new,
          name: "Tama",
          color: "white"
        )
      )

      result = Skit.serialize(container)

      expect(result).to eq({
                             "id" => 2,
                             "animal" => {
                               "type" => "cat",
                               "name" => "Tama",
                               "color" => "white"
                             }
                           })
    end

    it "round-trips Dog data correctly" do
      original_data = {
        "id" => 100,
        "animal" => {
          "type" => "dog",
          "name" => "Max",
          "breed" => "Golden Retriever"
        }
      }

      deserialized = Skit.deserialize(original_data, DiscriminatedUnionTest::AnimalContainer)
      serialized = Skit.serialize(deserialized)

      expect(serialized).to eq(original_data)
    end

    it "round-trips Cat data correctly" do
      original_data = {
        "id" => 200,
        "animal" => {
          "type" => "cat",
          "name" => "Whiskers",
          "color" => "orange"
        }
      }

      deserialized = Skit.deserialize(original_data, DiscriminatedUnionTest::AnimalContainer)
      serialized = Skit.serialize(deserialized)

      expect(serialized).to eq(original_data)
    end
  end

  describe "discriminated union with integer const" do
    before(:all) do
      module DiscriminatedUnionIntTest
        class StatusVal200 < Skit::JsonSchema::Types::Const
          VALUE = 200
        end

        class StatusVal404 < Skit::JsonSchema::Types::Const
          VALUE = 404
        end

        class SuccessResponse < T::Struct
          prop :status, StatusVal200
          prop :data, String
        end

        class NotFoundResponse < T::Struct
          prop :status, StatusVal404
          prop :message, String
        end

        class ResponseContainer < T::Struct
          prop :request_id, String
          prop :response, T.any(SuccessResponse, NotFoundResponse)
        end
      end
    end

    it "deserializes to SuccessResponse when status is 200" do
      container_data = {
        "request_id" => "abc123",
        "response" => {
          "status" => 200,
          "data" => "OK"
        }
      }

      result = Skit.deserialize(container_data, DiscriminatedUnionIntTest::ResponseContainer)

      expect(result.request_id).to eq("abc123")
      expect(result.response).to be_a(DiscriminatedUnionIntTest::SuccessResponse)
      expect(result.response.status.value).to eq(200)
      expect(result.response.data).to eq("OK")
    end

    it "deserializes to NotFoundResponse when status is 404" do
      container_data = {
        "request_id" => "def456",
        "response" => {
          "status" => 404,
          "message" => "Resource not found"
        }
      }

      result = Skit.deserialize(container_data, DiscriminatedUnionIntTest::ResponseContainer)

      expect(result.request_id).to eq("def456")
      expect(result.response).to be_a(DiscriminatedUnionIntTest::NotFoundResponse)
      expect(result.response.status.value).to eq(404)
      expect(result.response.message).to eq("Resource not found")
    end
  end

  describe "code generator behavior for oneOf with objects" do
    let(:schema) do
      {
        "type" => "object",
        "title" => "Container",
        "properties" => {
          "data" => {
            "oneOf" => [
              {
                "type" => "object",
                "properties" => {
                  "type" => { "const" => "dog" },
                  "breed" => { "type" => "string" }
                }
              },
              {
                "type" => "object",
                "properties" => {
                  "type" => { "const" => "cat" },
                  "color" => { "type" => "string" }
                }
              }
            ]
          }
        },
        "required" => ["data"]
      }
    end

    it "generates union type for oneOf with objects" do
      code = Skit::JsonSchema.generate(schema, module_name: "OneOfTest")

      # Should generate T.any(...) for object unions
      expect(code).to include("prop :data, T.any(")
      expect(code).not_to include("T.untyped")
    end

    it "generates nested structs for each union member" do
      code = Skit::JsonSchema.generate(schema, module_name: "OneOfTest")

      expect(code).to include("class ContainerDataVariant0 < T::Struct")
      expect(code).to include("class ContainerDataVariant1 < T::Struct")
    end

    it "generates const types for discriminator properties" do
      code = Skit::JsonSchema.generate(schema, module_name: "OneOfTest")

      expect(code).to include("class TypeDog < Skit::JsonSchema::Types::Const")
      expect(code).to include("class TypeCat < Skit::JsonSchema::Types::Const")
    end
  end
end
# rubocop:enable RSpec/DescribeClass, Lint/ConstantDefinitionInBlock
# rubocop:enable RSpec/BeforeAfterAll, RSpec/LeakyConstantDeclaration
