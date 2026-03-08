# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Skit::Serialization::Processor::Tuple, type: :unit do
  let(:registry) { Skit::Serialization::Registry.new }
  let(:float_float_type) { T::Utils.coerce([Float, Float]) }
  let(:string_integer_type) { T::Utils.coerce([String, Integer]) }
  let(:processor) { described_class.new(float_float_type, registry: registry) }

  before do
    registry.register(described_class)
    registry.register(Skit::Serialization::Processor::Array)
    registry.register(Skit::Serialization::Processor::SimpleType)
    registry.register(Skit::Serialization::Processor::String)
    registry.register(Skit::Serialization::Processor::Integer)
    registry.register(Skit::Serialization::Processor::Float)
  end

  describe ".handles?" do
    it "returns true for tuple type" do
      expect(described_class.handles?(float_float_type)).to be true
      expect(described_class.handles?(string_integer_type)).to be true
    end

    it "returns false for T::Array type" do
      array_type = T::Utils.coerce(T::Array[Float])
      expect(described_class.handles?(array_type)).to be false
    end

    it "returns false for other types" do
      expect(described_class.handles?(String)).to be false
      expect(described_class.handles?(nil)).to be false
    end
  end

  describe "#serialize" do
    it "serializes tuple of floats" do
      result = processor.serialize([1.0, 2.0])
      expect(result).to eq([1.0, 2.0])
    end

    it "serializes tuple of mixed types" do
      mixed_processor = described_class.new(string_integer_type, registry: registry)
      result = mixed_processor.serialize(["hello", 42])
      expect(result).to eq(["hello", 42])
    end

    it "raises error for non-array value" do
      expect { processor.serialize("not an array") }.to raise_error(
        Skit::Serialization::SerializeError,
        /Expected Array, got String/
      )
    end

    it "raises error for nil" do
      expect { processor.serialize(nil) }.to raise_error(
        Skit::Serialization::SerializeError,
        /Expected Array, got NilClass/
      )
    end
  end

  describe "#deserialize" do
    it "deserializes tuple of floats" do
      result = processor.deserialize([1.0, 2.0])
      expect(result).to eq([1.0, 2.0])
    end

    it "deserializes tuple of mixed types" do
      mixed_processor = described_class.new(string_integer_type, registry: registry)
      result = mixed_processor.deserialize(["hello", 42])
      expect(result).to eq(["hello", 42])
    end

    it "raises error for non-array value" do
      expect { processor.deserialize("not an array") }.to raise_error(
        Skit::Serialization::DeserializeError,
        /Expected Array, got String/
      )
    end

    it "raises error for nil" do
      expect { processor.deserialize(nil) }.to raise_error(
        Skit::Serialization::DeserializeError,
        /Expected Array, got NilClass/
      )
    end
  end

  describe "nested tuples" do
    let(:nested_type) { T::Utils.coerce([T::Array[Float], T::Array[Float]]) }
    let(:nested_processor) { described_class.new(nested_type, registry: registry) }

    it "serializes nested tuple" do
      result = nested_processor.serialize([[1.0, 2.0], [3.0, 4.0]])
      expect(result).to eq([[1.0, 2.0], [3.0, 4.0]])
    end

    it "deserializes nested tuple" do
      result = nested_processor.deserialize([[1.0, 2.0], [3.0, 4.0]])
      expect(result).to eq([[1.0, 2.0], [3.0, 4.0]])
    end
  end
end
