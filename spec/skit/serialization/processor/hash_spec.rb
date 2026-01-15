# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Skit::Serialization::Processor::Hash, type: :unit do
  let(:registry) { Skit::Serialization::Registry.new }
  let(:string_hash_type) { T::Utils.coerce(T::Hash[String, Integer]) }
  let(:symbol_hash_type) { T::Utils.coerce(T::Hash[Symbol, String]) }
  let(:processor) { described_class.new(string_hash_type, registry: registry) }

  before do
    registry.register(Skit::Serialization::Processor::String)
    registry.register(Skit::Serialization::Processor::Integer)
    registry.register(Skit::Serialization::Processor::SimpleType)
    registry.register(Skit::Serialization::Processor::Array)
    registry.register(described_class)
  end

  describe ".handles?" do
    it "returns true for T::Hash type" do
      expect(described_class.handles?(string_hash_type)).to be true
      expect(described_class.handles?(symbol_hash_type)).to be true
    end

    it "returns false for raw Hash class" do
      expect(described_class.handles?(Hash)).to be false
    end

    it "returns false for other types" do
      expect(described_class.handles?(String)).to be false
      expect(described_class.handles?(nil)).to be false
    end
  end

  describe "#serialize" do
    it "serializes empty hash" do
      result = processor.serialize({})
      expect(result).to eq({})
    end

    it "serializes hash with string keys" do
      result = processor.serialize({ "a" => 1, "b" => 2 })
      expect(result).to eq({ "a" => 1, "b" => 2 })
    end

    it "converts symbol keys to string keys" do
      result = processor.serialize({ a: 1, b: 2 })
      expect(result).to eq({ "a" => 1, "b" => 2 })
    end

    it "raises error for non-hash value" do
      expect { processor.serialize("not a hash") }.to raise_error(
        Skit::Serialization::TypeMismatchError,
        /Expected Hash, got String/
      )
    end

    it "raises error for nil" do
      expect { processor.serialize(nil) }.to raise_error(
        Skit::Serialization::TypeMismatchError,
        /Expected Hash, got NilClass/
      )
    end
  end

  describe "#deserialize" do
    it "deserializes empty hash" do
      result = processor.deserialize({})
      expect(result).to eq({})
    end

    it "deserializes hash and normalizes keys to string" do
      result = processor.deserialize({ "a" => 1, "b" => 2 })
      expect(result).to eq({ "a" => 1, "b" => 2 })
    end

    context "with symbol key type" do
      let(:symbol_processor) { described_class.new(symbol_hash_type, registry: registry) }

      it "normalizes keys to symbols" do
        result = symbol_processor.deserialize({ "a" => "x", "b" => "y" })
        expect(result).to eq({ a: "x", b: "y" })
      end
    end

    it "raises error for non-hash value" do
      expect { processor.deserialize("not a hash") }.to raise_error(
        Skit::Serialization::DeserializationError,
        /Expected Hash, got String/
      )
    end

    it "raises error for nil" do
      expect { processor.deserialize(nil) }.to raise_error(
        Skit::Serialization::DeserializationError,
        /Expected Hash, got NilClass/
      )
    end
  end

  describe "nested structures" do
    let(:nested_hash_type) { T::Utils.coerce(T::Hash[String, T::Array[Integer]]) }
    let(:nested_processor) { described_class.new(nested_hash_type, registry: registry) }

    it "serializes hash with array values" do
      result = nested_processor.serialize({ "nums" => [1, 2, 3] })
      expect(result).to eq({ "nums" => [1, 2, 3] })
    end

    it "deserializes hash with array values" do
      result = nested_processor.deserialize({ "nums" => [1, 2, 3] })
      expect(result).to eq({ "nums" => [1, 2, 3] })
    end
  end
end
