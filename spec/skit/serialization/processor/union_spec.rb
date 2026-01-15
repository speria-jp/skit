# typed: false
# frozen_string_literal: true

require "spec_helper"

# Must use constants for T.any to work correctly with anonymous T::Struct classes
module UnionSpecTestClasses
  class Dog < T::Struct
    const :name, String
    const :breed, String
  end

  class Cat < T::Struct
    const :name, String
    const :indoor, T::Boolean
  end
end

RSpec.describe Skit::Serialization::Processor::Union, type: :unit do
  let(:registry) { Skit::Serialization::Registry.new }
  let(:union_type) { T::Utils.coerce(T.any(UnionSpecTestClasses::Dog, UnionSpecTestClasses::Cat)) }
  let(:processor) { described_class.new(union_type, registry: registry) }

  before do
    registry.register(Skit::Serialization::Processor::String)
    registry.register(Skit::Serialization::Processor::Boolean)
    registry.register(Skit::Serialization::Processor::SimpleType)
    registry.register(Skit::Serialization::Processor::Struct)
    registry.register(described_class)
  end

  describe ".handles?" do
    it "returns true for union of T::Struct types" do
      expect(described_class.handles?(union_type)).to be true
    end

    it "returns false for nilable types" do
      nilable_type = T::Utils.coerce(T.nilable(String))
      expect(described_class.handles?(nilable_type)).to be false
    end

    it "returns false for T::Boolean" do
      boolean_type = T::Utils.coerce(T::Boolean)
      expect(described_class.handles?(boolean_type)).to be false
    end

    it "returns false for non-union types" do
      expect(described_class.handles?(String)).to be false
      expect(described_class.handles?(T::Utils.coerce(String))).to be false
    end
  end

  describe "#serialize" do
    it "serializes dog struct" do
      dog = UnionSpecTestClasses::Dog.new(name: "Buddy", breed: "Labrador")
      result = processor.serialize(dog)
      expect(result).to eq({ "name" => "Buddy", "breed" => "Labrador" })
    end

    it "serializes cat struct" do
      cat = UnionSpecTestClasses::Cat.new(name: "Whiskers", indoor: true)
      result = processor.serialize(cat)
      expect(result).to eq({ "name" => "Whiskers", "indoor" => true })
    end

    it "raises error for non-union member" do
      expect { processor.serialize("not a struct") }.to raise_error(
        Skit::Serialization::TypeMismatchError,
        /is not a member of this union/
      )
    end

    it "raises error for nil" do
      expect { processor.serialize(nil) }.to raise_error(
        Skit::Serialization::TypeMismatchError,
        /is not a member of this union/
      )
    end
  end

  describe "#deserialize" do
    it "returns struct instance as-is" do
      dog = UnionSpecTestClasses::Dog.new(name: "Buddy", breed: "Labrador")
      result = processor.deserialize(dog)
      expect(result).to eq(dog)
    end

    it "deserializes hash to matching struct (dog)" do
      hash = { "name" => "Buddy", "breed" => "Labrador" }
      result = processor.deserialize(hash)
      expect(result).to be_a(UnionSpecTestClasses::Dog)
      expect(result.name).to eq("Buddy")
      expect(result.breed).to eq("Labrador")
    end

    it "deserializes hash to matching struct (cat)" do
      hash = { "name" => "Whiskers", "indoor" => true }
      result = processor.deserialize(hash)
      expect(result).to be_a(UnionSpecTestClasses::Cat)
      expect(result.name).to eq("Whiskers")
      expect(result.indoor).to be true
    end

    it "raises error for non-hash value" do
      expect { processor.deserialize("not a hash") }.to raise_error(
        Skit::Serialization::DeserializationError,
        /Expected Hash or union member struct/
      )
    end

    it "raises error for nil" do
      expect { processor.deserialize(nil) }.to raise_error(
        Skit::Serialization::DeserializationError,
        /Expected Hash or union member struct/
      )
    end

    it "raises error when no struct matches" do
      hash = { "unknown" => "field" }
      expect { processor.deserialize(hash) }.to raise_error(
        Skit::Serialization::DeserializationError,
        /No matching struct found for union/
      )
    end
  end
end
