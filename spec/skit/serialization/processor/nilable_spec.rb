# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Skit::Serialization::Processor::Nilable, type: :unit do
  let(:registry) { Skit::Serialization::Registry.new }
  let(:nilable_string_type) { T::Utils.coerce(T.nilable(String)) }
  let(:nilable_integer_type) { T::Utils.coerce(T.nilable(Integer)) }
  let(:processor) { described_class.new(nilable_string_type, registry: registry) }

  before do
    registry.register(Skit::Serialization::Processor::String)
    registry.register(Skit::Serialization::Processor::Integer)
    registry.register(Skit::Serialization::Processor::SimpleType)
    registry.register(described_class)
  end

  describe ".handles?" do
    it "returns true for T.nilable types" do
      expect(described_class.handles?(nilable_string_type)).to be true
      expect(described_class.handles?(nilable_integer_type)).to be true
    end

    it "returns false for non-nilable types" do
      expect(described_class.handles?(T::Utils.coerce(String))).to be false
      expect(described_class.handles?(String)).to be false
    end

    it "returns false for general unions" do
      # T::Boolean is actually a union of TrueClass and FalseClass
      expect(described_class.handles?(T::Utils.coerce(T::Boolean))).to be false
    end
  end

  describe "#serialize" do
    it "serializes nil to nil" do
      result = processor.serialize(nil)
      expect(result).to be_nil
    end

    it "serializes non-nil value using inner type" do
      result = processor.serialize("hello")
      expect(result).to eq("hello")
    end

    it "raises error for type mismatch" do
      expect { processor.serialize(123) }.to raise_error(
        Skit::Serialization::TypeMismatchError,
        /Expected String/
      )
    end
  end

  describe "#deserialize" do
    it "deserializes nil to nil" do
      result = processor.deserialize(nil)
      expect(result).to be_nil
    end

    it "deserializes non-nil value using inner type" do
      result = processor.deserialize("hello")
      expect(result).to eq("hello")
    end

    it "works with Integer type" do
      int_processor = described_class.new(nilable_integer_type, registry: registry)
      expect(int_processor.deserialize(nil)).to be_nil
      expect(int_processor.deserialize(42)).to eq(42)
    end
  end

  describe "round-trip serialization" do
    it "preserves nil" do
      serialized = processor.serialize(nil)
      deserialized = processor.deserialize(serialized)
      expect(deserialized).to be_nil
    end

    it "preserves non-nil value" do
      serialized = processor.serialize("hello")
      deserialized = processor.deserialize(serialized)
      expect(deserialized).to eq("hello")
    end
  end
end
