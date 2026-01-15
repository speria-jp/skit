# typed: false
# frozen_string_literal: true

require "spec_helper"
require "date"

RSpec.describe Skit::Serialization::Processor::Date, type: :unit do
  let(:registry) { Skit::Serialization::Registry.new }
  let(:processor) { described_class.new(Date, registry: registry) }

  describe ".handles?" do
    it "returns true for Date class" do
      expect(described_class.handles?(Date)).to be true
    end

    it "returns false for other types" do
      expect(described_class.handles?(Time)).to be false
      expect(described_class.handles?(String)).to be false
    end
  end

  describe "#serialize" do
    it "serializes Date to ISO 8601 string" do
      date = Date.new(2025, 1, 15)
      expect(processor.serialize(date)).to eq("2025-01-15")
    end

    it "raises error for non-Date values" do
      expect { processor.serialize("2025-01-15") }.to raise_error(
        Skit::Serialization::TypeMismatchError,
        "Expected Date, got String"
      )
      expect { processor.serialize(Time.now) }.to raise_error(
        Skit::Serialization::TypeMismatchError,
        "Expected Date, got Time"
      )
      expect { processor.serialize(nil) }.to raise_error(
        Skit::Serialization::TypeMismatchError,
        "Expected Date, got NilClass"
      )
    end
  end

  describe "#deserialize" do
    it "deserializes ISO 8601 string to Date" do
      result = processor.deserialize("2025-01-15")
      expect(result).to eq(Date.new(2025, 1, 15))
    end

    it "returns Date as-is" do
      date = Date.new(2025, 1, 15)
      expect(processor.deserialize(date)).to eq(date)
    end

    it "raises error for invalid date string" do
      expect { processor.deserialize("invalid") }.to raise_error(
        Skit::Serialization::DeserializationError,
        /Failed to deserialize Date/
      )
    end

    it "raises error for non-Date/String values" do
      expect { processor.deserialize(123) }.to raise_error(
        Skit::Serialization::DeserializationError,
        "Expected Date or String, got Integer"
      )
      expect { processor.deserialize(nil) }.to raise_error(
        Skit::Serialization::DeserializationError,
        "Expected Date or String, got NilClass"
      )
    end
  end
end
