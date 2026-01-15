# typed: false
# frozen_string_literal: true

require "spec_helper"

# Must use constants for T::Struct classes to work correctly with Sorbet
module StructSpecTestClasses
  class Item < T::Struct
    const :name, String
    const :quantity, Integer
  end
end

RSpec.describe Skit::Serialization::Processor::Struct, type: :unit do
  let(:registry) { Skit::Serialization::Registry.new }
  let(:processor) { described_class.new(StructSpecTestClasses::Item, registry: registry) }

  before do
    registry.register(Skit::Serialization::Processor::Integer)
    registry.register(Skit::Serialization::Processor::String)
    registry.register(Skit::Serialization::Processor::SimpleType)
    registry.register(described_class)
  end

  describe ".handles?" do
    it "returns true for T::Struct class" do
      expect(described_class.handles?(StructSpecTestClasses::Item)).to be true
    end

    it "returns false for non-T::Struct types" do
      expect(described_class.handles?(String)).to be false
      expect(described_class.handles?(Integer)).to be false
      expect(described_class.handles?(Hash)).to be false
    end
  end

  describe "#serialize" do
    it "raises error for nil" do
      expect { processor.serialize(nil) }.to raise_error(
        Skit::Serialization::TypeMismatchError,
        /got NilClass/
      )
    end

    it "raises error for non-struct value" do
      expect { processor.serialize("not a struct") }.to raise_error(
        Skit::Serialization::TypeMismatchError,
        /got String/
      )
    end

    it "serializes basic T::Struct instance" do
      item = StructSpecTestClasses::Item.new(name: "test", quantity: 5)
      result = processor.serialize(item)
      expect(result).to eq({ "name" => "test", "quantity" => 5 })
    end
  end

  describe "#deserialize" do
    it "raises error for nil" do
      expect { processor.deserialize(nil) }.to raise_error(
        Skit::Serialization::DeserializationError,
        /Expected Hash, got NilClass/
      )
    end

    it "returns struct instance as-is" do
      item = StructSpecTestClasses::Item.new(name: "test", quantity: 5)
      result = processor.deserialize(item)
      expect(result).to eq(item)
    end

    it "raises error for non-hash value" do
      expect { processor.deserialize("not a hash") }.to raise_error(
        Skit::Serialization::DeserializationError,
        /Expected Hash, got String/
      )
    end

    it "deserializes hash with string keys" do
      hash = { "name" => "test", "quantity" => 5 }
      result = processor.deserialize(hash)
      expect(result).to be_a(StructSpecTestClasses::Item)
      expect(result.name).to eq("test")
      expect(result.quantity).to eq(5)
    end

    it "deserializes hash with symbol keys" do
      hash = { name: "test", quantity: 5 }
      result = processor.deserialize(hash)
      expect(result).to be_a(StructSpecTestClasses::Item)
      expect(result.name).to eq("test")
      expect(result.quantity).to eq(5)
    end

    it "deserializes hash with mixed keys" do
      hash = { "name" => "test", quantity: 5 }
      result = processor.deserialize(hash)
      expect(result).to be_a(StructSpecTestClasses::Item)
      expect(result.name).to eq("test")
      expect(result.quantity).to eq(5)
    end
  end

  describe "round-trip serialization" do
    it "preserves data through serialize and deserialize" do
      original = StructSpecTestClasses::Item.new(name: "test", quantity: 5)
      serialized = processor.serialize(original)
      deserialized = processor.deserialize(serialized)

      expect(deserialized).to be_a(StructSpecTestClasses::Item)
      expect(deserialized.name).to eq(original.name)
      expect(deserialized.quantity).to eq(original.quantity)
    end
  end
end
