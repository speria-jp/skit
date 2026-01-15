# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Skit::Serialization::Processor::Float, type: :unit do
  let(:registry) { Skit::Serialization::Registry.new }
  let(:processor) { described_class.new(Float, registry: registry) }

  describe ".handles?" do
    it "returns true for Float class" do
      expect(described_class.handles?(Float)).to be true
    end

    it "returns false for other types" do
      expect(described_class.handles?(Integer)).to be false
      expect(described_class.handles?(String)).to be false
    end
  end

  describe "#serialize" do
    it "serializes float to float" do
      expect(processor.serialize(1.5)).to eq(1.5)
    end

    it "raises error for non-float values" do
      expect { processor.serialize(123) }.to raise_error(
        Skit::Serialization::TypeMismatchError,
        "Expected Float, got Integer"
      )
      expect { processor.serialize("1.5") }.to raise_error(
        Skit::Serialization::TypeMismatchError,
        "Expected Float, got String"
      )
      expect { processor.serialize(nil) }.to raise_error(
        Skit::Serialization::TypeMismatchError,
        "Expected Float, got NilClass"
      )
    end
  end

  describe "#deserialize" do
    it "deserializes float to float" do
      expect(processor.deserialize(1.5)).to eq(1.5)
    end

    it "converts integer to float" do
      expect(processor.deserialize(42)).to eq(42.0)
    end

    it "raises error for non-numeric values" do
      expect { processor.deserialize("1.5") }.to raise_error(
        Skit::Serialization::DeserializationError,
        "Expected Float or Integer, got String"
      )
      expect { processor.deserialize(nil) }.to raise_error(
        Skit::Serialization::DeserializationError,
        "Expected Float or Integer, got NilClass"
      )
    end
  end
end
