# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Skit::Serialization::Processor::Integer, type: :unit do
  let(:registry) { Skit::Serialization::Registry.new }
  let(:processor) { described_class.new(Integer, registry: registry) }

  describe ".handles?" do
    it "returns true for Integer class" do
      expect(described_class.handles?(Integer)).to be true
    end

    it "returns false for other types" do
      expect(described_class.handles?(String)).to be false
      expect(described_class.handles?(Float)).to be false
    end
  end

  describe "#serialize" do
    it "serializes integer to integer" do
      expect(processor.serialize(123)).to eq(123)
    end

    it "raises error for non-integer values" do
      expect { processor.serialize("123") }.to raise_error(
        Skit::Serialization::SerializeError,
        "Expected Integer, got String"
      )
      expect { processor.serialize(1.5) }.to raise_error(
        Skit::Serialization::SerializeError,
        "Expected Integer, got Float"
      )
      expect { processor.serialize(nil) }.to raise_error(
        Skit::Serialization::SerializeError,
        "Expected Integer, got NilClass"
      )
    end
  end

  describe "#deserialize" do
    it "deserializes integer to integer" do
      expect(processor.deserialize(123)).to eq(123)
    end

    it "raises error for non-integer values" do
      expect { processor.deserialize("123") }.to raise_error(
        Skit::Serialization::DeserializeError,
        "Expected Integer, got String"
      )
      expect { processor.deserialize(nil) }.to raise_error(
        Skit::Serialization::DeserializeError,
        "Expected Integer, got NilClass"
      )
    end
  end
end
