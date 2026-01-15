# typed: false
# frozen_string_literal: true

require "spec_helper"
require "active_model"

module AttributeSpecTestClasses
  class Box < T::Struct
    const :width, Integer
    const :height, Integer
  end

  class Person < T::Struct
    const :name, String
    const :age, Integer
    const :email, T.nilable(String)
  end
end

RSpec.describe Skit::Attribute, type: :unit do
  let(:type) { described_class.new(AttributeSpecTestClasses::Box) }

  describe ".[]" do
    it "creates an Attribute instance for the given type" do
      attr = described_class[AttributeSpecTestClasses::Box]
      expect(attr).to be_a(described_class)
    end
  end

  describe "#cast" do
    context "when value is a Hash" do
      it "converts Hash with symbol keys to T::Struct instance" do
        result = type.cast({ width: 100, height: 200 })

        expect(result).to be_a(AttributeSpecTestClasses::Box)
        expect(result.width).to eq(100)
        expect(result.height).to eq(200)
      end

      it "converts Hash with string keys to T::Struct instance" do
        result = type.cast({ "width" => 100, "height" => 200 })

        expect(result).to be_a(AttributeSpecTestClasses::Box)
        expect(result.width).to eq(100)
        expect(result.height).to eq(200)
      end
    end

    context "when value is nil" do
      it "returns nil" do
        expect(type.cast(nil)).to be_nil
      end
    end

    context "when value is already a T::Struct instance" do
      it "returns the same instance" do
        box = AttributeSpecTestClasses::Box.new(width: 100, height: 200)
        result = type.cast(box)

        expect(result).to be(box)
      end
    end

    context "when value is invalid" do
      it "raises DeserializationError for string values" do
        expect { type.cast("invalid") }.to raise_error(
          Skit::Serialization::DeserializationError,
          /Expected Hash/
        )
      end

      it "raises DeserializationError for numeric values" do
        expect { type.cast(123) }.to raise_error(
          Skit::Serialization::DeserializationError,
          /Expected Hash/
        )
      end
    end
  end

  describe "#serialize" do
    it "converts T::Struct to JSON string" do
      box = AttributeSpecTestClasses::Box.new(width: 100, height: 200)
      result = type.serialize(box)

      expect(result).to be_a(String)
      parsed = JSON.parse(result)
      expect(parsed).to eq({ "width" => 100, "height" => 200 })
    end

    it "returns nil for nil value" do
      expect(type.serialize(nil)).to be_nil
    end
  end

  describe "#deserialize" do
    it "converts JSON string to T::Struct instance" do
      json = '{"width":100,"height":200}'
      result = type.deserialize(json)

      expect(result).to be_a(AttributeSpecTestClasses::Box)
      expect(result.width).to eq(100)
      expect(result.height).to eq(200)
    end

    it "converts Hash to T::Struct instance" do
      hash = { "width" => 100, "height" => 200 }
      result = type.deserialize(hash)

      expect(result).to be_a(AttributeSpecTestClasses::Box)
      expect(result.width).to eq(100)
      expect(result.height).to eq(200)
    end

    it "returns nil for nil value" do
      expect(type.deserialize(nil)).to be_nil
    end

    context "with invalid JSON" do
      it "raises DeserializationError for numeric JSON" do
        expect { type.deserialize("123") }.to raise_error(
          Skit::Serialization::DeserializationError,
          /Expected Hash/
        )
      end
    end
  end

  describe "with nilable fields" do
    let(:person_type) { described_class.new(AttributeSpecTestClasses::Person) }

    it "handles nil values in nilable fields" do
      hash = { "name" => "Alice", "age" => 30, "email" => nil }
      result = person_type.cast(hash)

      expect(result.name).to eq("Alice")
      expect(result.age).to eq(30)
      expect(result.email).to be_nil
    end

    it "serializes nil values in nilable fields" do
      person = AttributeSpecTestClasses::Person.new(name: "Alice", age: 30, email: nil)
      result = person_type.serialize(person)

      parsed = JSON.parse(result)
      expect(parsed["email"]).to be_nil
    end
  end
end
