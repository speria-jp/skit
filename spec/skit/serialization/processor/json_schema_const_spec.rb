# typed: false
# frozen_string_literal: true

require "spec_helper"

module JsonSchemaConstSpecTestClasses
  class DogType < Skit::JsonSchema::Types::Const
    VALUE = "dog"
  end

  class CatType < Skit::JsonSchema::Types::Const
    VALUE = "cat"
  end

  class StatusCode < Skit::JsonSchema::Types::Const
    VALUE = 200
  end

  class PriceMultiplier < Skit::JsonSchema::Types::Const
    VALUE = 1.5
  end

  class EnabledFlag < Skit::JsonSchema::Types::Const
    VALUE = true
  end

  class DisabledFlag < Skit::JsonSchema::Types::Const
    VALUE = false
  end
end

RSpec.describe Skit::Serialization::Processor::JsonSchemaConst, type: :unit do
  let(:registry) { Skit::Serialization::Registry.new }
  let(:dog_processor) { described_class.new(JsonSchemaConstSpecTestClasses::DogType, registry: registry) }
  let(:status_processor) { described_class.new(JsonSchemaConstSpecTestClasses::StatusCode, registry: registry) }
  let(:float_processor) { described_class.new(JsonSchemaConstSpecTestClasses::PriceMultiplier, registry: registry) }
  let(:true_processor) { described_class.new(JsonSchemaConstSpecTestClasses::EnabledFlag, registry: registry) }
  let(:false_processor) { described_class.new(JsonSchemaConstSpecTestClasses::DisabledFlag, registry: registry) }

  describe ".handles?" do
    it "returns true for Skit::JsonSchema::Types::Const subclass" do
      expect(described_class.handles?(JsonSchemaConstSpecTestClasses::DogType)).to be true
    end

    it "returns true for integer const class" do
      expect(described_class.handles?(JsonSchemaConstSpecTestClasses::StatusCode)).to be true
    end

    it "returns false for T::Struct" do
      struct_class = Class.new(T::Struct) do
        const :name, String
      end
      expect(described_class.handles?(struct_class)).to be false
    end

    it "returns false for raw classes" do
      expect(described_class.handles?(String)).to be false
      expect(described_class.handles?(Integer)).to be false
    end

    it "returns false for non-class types" do
      expect(described_class.handles?("string")).to be false
      expect(described_class.handles?(123)).to be false
    end
  end

  describe "#serialize" do
    context "with string const" do
      it "returns the const value" do
        instance = JsonSchemaConstSpecTestClasses::DogType.new
        result = dog_processor.serialize(instance)
        expect(result).to eq("dog")
      end
    end

    context "with integer const" do
      it "returns the const value" do
        instance = JsonSchemaConstSpecTestClasses::StatusCode.new
        result = status_processor.serialize(instance)
        expect(result).to eq(200)
      end
    end

    context "with float const" do
      it "returns the const value" do
        instance = JsonSchemaConstSpecTestClasses::PriceMultiplier.new
        result = float_processor.serialize(instance)
        expect(result).to eq(1.5)
      end
    end

    context "with boolean const" do
      it "returns true for true const" do
        instance = JsonSchemaConstSpecTestClasses::EnabledFlag.new
        result = true_processor.serialize(instance)
        expect(result).to be(true)
      end

      it "returns false for false const" do
        instance = JsonSchemaConstSpecTestClasses::DisabledFlag.new
        result = false_processor.serialize(instance)
        expect(result).to be(false)
      end
    end

    context "with wrong type" do
      it "raises TypeMismatchError for wrong const class" do
        cat_instance = JsonSchemaConstSpecTestClasses::CatType.new
        expect { dog_processor.serialize(cat_instance) }.to raise_error(
          Skit::Serialization::TypeMismatchError,
          /Expected.*DogType.*got.*CatType/
        )
      end

      it "raises TypeMismatchError for nil" do
        expect { dog_processor.serialize(nil) }.to raise_error(
          Skit::Serialization::TypeMismatchError
        )
      end

      it "raises TypeMismatchError for raw value" do
        expect { dog_processor.serialize("dog") }.to raise_error(
          Skit::Serialization::TypeMismatchError
        )
      end
    end
  end

  describe "#deserialize" do
    context "with string const" do
      it "returns instance when value matches" do
        result = dog_processor.deserialize("dog")
        expect(result).to be_a(JsonSchemaConstSpecTestClasses::DogType)
        expect(result.value).to eq("dog")
      end

      it "raises DeserializationError when value does not match" do
        expect { dog_processor.deserialize("cat") }.to raise_error(
          Skit::Serialization::DeserializationError,
          /Expected "dog", got "cat"/
        )
      end
    end

    context "with integer const" do
      it "returns instance when value matches" do
        result = status_processor.deserialize(200)
        expect(result).to be_a(JsonSchemaConstSpecTestClasses::StatusCode)
        expect(result.value).to eq(200)
      end

      it "raises DeserializationError when value does not match" do
        expect { status_processor.deserialize(404) }.to raise_error(
          Skit::Serialization::DeserializationError,
          /Expected 200, got 404/
        )
      end

      it "raises DeserializationError for string representation of number" do
        expect { status_processor.deserialize("200") }.to raise_error(
          Skit::Serialization::DeserializationError
        )
      end
    end

    context "with float const" do
      it "returns instance when value matches" do
        result = float_processor.deserialize(1.5)
        expect(result).to be_a(JsonSchemaConstSpecTestClasses::PriceMultiplier)
      end

      it "raises DeserializationError when value does not match" do
        expect { float_processor.deserialize(2.0) }.to raise_error(
          Skit::Serialization::DeserializationError
        )
      end
    end

    context "with boolean const" do
      it "returns instance when true matches true" do
        result = true_processor.deserialize(true)
        expect(result).to be_a(JsonSchemaConstSpecTestClasses::EnabledFlag)
      end

      it "returns instance when false matches false" do
        result = false_processor.deserialize(false)
        expect(result).to be_a(JsonSchemaConstSpecTestClasses::DisabledFlag)
      end

      it "raises DeserializationError when true expected but false given" do
        expect { true_processor.deserialize(false) }.to raise_error(
          Skit::Serialization::DeserializationError
        )
      end

      it "raises DeserializationError when false expected but true given" do
        expect { false_processor.deserialize(true) }.to raise_error(
          Skit::Serialization::DeserializationError
        )
      end
    end

    context "when value is already correct instance" do
      it "returns the same instance" do
        instance = JsonSchemaConstSpecTestClasses::DogType.new
        result = dog_processor.deserialize(instance)
        expect(result).to be(instance)
      end
    end
  end

  describe "round-trip serialization" do
    it "preserves string const through serialize and deserialize" do
      original = JsonSchemaConstSpecTestClasses::DogType.new
      serialized = dog_processor.serialize(original)
      deserialized = dog_processor.deserialize(serialized)

      expect(deserialized).to be_a(JsonSchemaConstSpecTestClasses::DogType)
      expect(deserialized.value).to eq(original.value)
    end

    it "preserves integer const through serialize and deserialize" do
      original = JsonSchemaConstSpecTestClasses::StatusCode.new
      serialized = status_processor.serialize(original)
      deserialized = status_processor.deserialize(serialized)

      expect(deserialized).to be_a(JsonSchemaConstSpecTestClasses::StatusCode)
      expect(deserialized.value).to eq(original.value)
    end
  end
end
