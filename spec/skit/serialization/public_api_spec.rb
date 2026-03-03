# typed: false
# frozen_string_literal: true

require "spec_helper"

module PublicApiTestClasses
  class Address < T::Struct
    const :city, String
    const :zip, String
  end

  class Person < T::Struct
    const :name, String
    const :age, Integer
    const :email, T.nilable(String)
    const :address, Address
    const :tags, T::Array[String]
  end
end

# rubocop:disable RSpec/SpecFilePathFormat
RSpec.describe Skit, type: :unit do
  # rubocop:enable RSpec/SpecFilePathFormat
  describe "Skit.serialize" do
    it "serializes a simple T::Struct" do
      address = PublicApiTestClasses::Address.new(city: "Tokyo", zip: "100-0001")
      result = described_class.serialize(address)

      expect(result).to eq({
                             "city" => "Tokyo",
                             "zip" => "100-0001"
                           })
    end

    it "serializes a nested T::Struct" do
      address = PublicApiTestClasses::Address.new(city: "Tokyo", zip: "100-0001")
      person = PublicApiTestClasses::Person.new(
        name: "Alice",
        age: 30,
        email: "alice@example.com",
        address: address,
        tags: %w[developer ruby]
      )

      result = described_class.serialize(person)

      expect(result).to eq({
                             "name" => "Alice",
                             "age" => 30,
                             "email" => "alice@example.com",
                             "address" => {
                               "city" => "Tokyo",
                               "zip" => "100-0001"
                             },
                             "tags" => %w[developer ruby]
                           })
    end

    it "serializes nil values in nilable fields" do
      address = PublicApiTestClasses::Address.new(city: "Tokyo", zip: "100-0001")
      person = PublicApiTestClasses::Person.new(
        name: "Bob",
        age: 25,
        email: nil,
        address: address,
        tags: []
      )

      result = described_class.serialize(person)

      expect(result["email"]).to be_nil
      expect(result["tags"]).to eq([])
    end

    it "raises error for non-T::Struct value" do
      # Sorbet runtime raises TypeError for type mismatch
      expect { described_class.serialize("not a struct") }.to raise_error(TypeError)
    end
  end

  describe "Skit.deserialize" do
    it "deserializes a simple Hash to T::Struct" do
      hash = { "city" => "Tokyo", "zip" => "100-0001" }
      result = described_class.deserialize(hash, PublicApiTestClasses::Address)

      expect(result).to be_a(PublicApiTestClasses::Address)
      expect(result.city).to eq("Tokyo")
      expect(result.zip).to eq("100-0001")
    end

    it "deserializes a nested Hash to T::Struct" do
      hash = {
        "name" => "Alice",
        "age" => 30,
        "email" => "alice@example.com",
        "address" => {
          "city" => "Tokyo",
          "zip" => "100-0001"
        },
        "tags" => %w[developer ruby]
      }

      result = described_class.deserialize(hash, PublicApiTestClasses::Person)

      expect(result).to be_a(PublicApiTestClasses::Person)
      expect(result.name).to eq("Alice")
      expect(result.age).to eq(30)
      expect(result.email).to eq("alice@example.com")
      expect(result.address).to be_a(PublicApiTestClasses::Address)
      expect(result.address.city).to eq("Tokyo")
      expect(result.tags).to eq(%w[developer ruby])
    end

    it "handles nil values in nilable fields" do
      hash = {
        "name" => "Bob",
        "age" => 25,
        "email" => nil,
        "address" => { "city" => "Osaka", "zip" => "530-0001" },
        "tags" => []
      }

      result = described_class.deserialize(hash, PublicApiTestClasses::Person)

      expect(result.email).to be_nil
      expect(result.tags).to eq([])
    end

    it "raises error for invalid type" do
      expect { described_class.deserialize("not a hash", PublicApiTestClasses::Address) }.to raise_error(
        Skit::Serialization::DeserializeError
      )
    end
  end

  describe "round-trip serialization" do
    it "preserves data through serialize and deserialize" do
      address = PublicApiTestClasses::Address.new(city: "Tokyo", zip: "100-0001")
      person = PublicApiTestClasses::Person.new(
        name: "Alice",
        age: 30,
        email: "alice@example.com",
        address: address,
        tags: %w[developer ruby]
      )

      serialized = described_class.serialize(person)
      deserialized = described_class.deserialize(serialized, PublicApiTestClasses::Person)

      expect(deserialized.name).to eq(person.name)
      expect(deserialized.age).to eq(person.age)
      expect(deserialized.email).to eq(person.email)
      expect(deserialized.address.city).to eq(person.address.city)
      expect(deserialized.address.zip).to eq(person.address.zip)
      expect(deserialized.tags).to eq(person.tags)
    end
  end
end
