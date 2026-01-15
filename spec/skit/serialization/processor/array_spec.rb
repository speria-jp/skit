# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Skit::Serialization::Processor::Array, type: :unit do
  let(:registry) { Skit::Serialization::Registry.new }
  let(:string_array_type) { T::Utils.coerce(T::Array[String]) }
  let(:integer_array_type) { T::Utils.coerce(T::Array[Integer]) }
  let(:processor) { described_class.new(string_array_type, registry: registry) }

  before do
    registry.register(Skit::Serialization::Processor::String)
    registry.register(Skit::Serialization::Processor::Integer)
    registry.register(Skit::Serialization::Processor::SimpleType)
    registry.register(described_class)
  end

  describe ".handles?" do
    it "returns true for T::Array type" do
      expect(described_class.handles?(string_array_type)).to be true
      expect(described_class.handles?(integer_array_type)).to be true
    end

    it "returns false for raw Array class" do
      expect(described_class.handles?(Array)).to be false
    end

    it "returns false for other types" do
      expect(described_class.handles?(String)).to be false
      expect(described_class.handles?(nil)).to be false
    end
  end

  describe "#serialize" do
    it "serializes empty array" do
      result = processor.serialize([])
      expect(result).to eq([])
    end

    it "serializes array of strings" do
      result = processor.serialize(%w[hello world])
      expect(result).to eq(%w[hello world])
    end

    it "serializes array of integers" do
      int_processor = described_class.new(integer_array_type, registry: registry)
      result = int_processor.serialize([1, 2, 3])
      expect(result).to eq([1, 2, 3])
    end

    it "raises error for non-array value" do
      expect { processor.serialize("not an array") }.to raise_error(
        Skit::Serialization::TypeMismatchError,
        /Expected Array, got String/
      )
    end

    it "raises error for nil" do
      expect { processor.serialize(nil) }.to raise_error(
        Skit::Serialization::TypeMismatchError,
        /Expected Array, got NilClass/
      )
    end
  end

  describe "#deserialize" do
    it "deserializes empty array" do
      result = processor.deserialize([])
      expect(result).to eq([])
    end

    it "deserializes array of strings" do
      result = processor.deserialize(%w[hello world])
      expect(result).to eq(%w[hello world])
    end

    it "deserializes array of integers" do
      int_processor = described_class.new(integer_array_type, registry: registry)
      result = int_processor.deserialize([1, 2, 3])
      expect(result).to eq([1, 2, 3])
    end

    it "raises error for non-array value" do
      expect { processor.deserialize("not an array") }.to raise_error(
        Skit::Serialization::DeserializationError,
        /Expected Array, got String/
      )
    end

    it "raises error for nil" do
      expect { processor.deserialize(nil) }.to raise_error(
        Skit::Serialization::DeserializationError,
        /Expected Array, got NilClass/
      )
    end
  end

  describe "nested arrays" do
    let(:nested_array_type) { T::Utils.coerce(T::Array[T::Array[Integer]]) }
    let(:nested_processor) { described_class.new(nested_array_type, registry: registry) }

    it "serializes nested arrays" do
      result = nested_processor.serialize([[1, 2], [3, 4]])
      expect(result).to eq([[1, 2], [3, 4]])
    end

    it "deserializes nested arrays" do
      result = nested_processor.deserialize([[1, 2], [3, 4]])
      expect(result).to eq([[1, 2], [3, 4]])
    end
  end
end
