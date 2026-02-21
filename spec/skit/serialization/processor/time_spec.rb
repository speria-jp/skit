# typed: false
# frozen_string_literal: true

require "spec_helper"
require "time"

RSpec.describe Skit::Serialization::Processor::Time, type: :unit do
  let(:registry) { Skit::Serialization::Registry.new }
  let(:processor) { described_class.new(Time, registry: registry) }

  describe ".handles?" do
    it "returns true for Time class" do
      expect(described_class.handles?(Time)).to be true
    end

    it "returns false for other types" do
      expect(described_class.handles?(Date)).to be false
      expect(described_class.handles?(String)).to be false
    end
  end

  describe "#serialize" do
    it "serializes Time to ISO 8601 string" do
      time = Time.new(2025, 1, 15, 10, 30, 0, "+09:00")
      expect(processor.serialize(time)).to eq("2025-01-15T10:30:00+09:00")
    end

    it "serializes UTC time with Z notation" do
      time = Time.utc(2025, 1, 15, 10, 30, 0)
      expect(processor.serialize(time)).to eq("2025-01-15T10:30:00Z")
    end

    it "raises error for non-Time values" do
      expect { processor.serialize("2025-01-15T10:30:00+09:00") }.to raise_error(
        Skit::Serialization::SerializeError,
        "Expected Time, got String"
      )
      expect { processor.serialize(Date.today) }.to raise_error(
        Skit::Serialization::SerializeError,
        "Expected Time, got Date"
      )
      expect { processor.serialize(nil) }.to raise_error(
        Skit::Serialization::SerializeError,
        "Expected Time, got NilClass"
      )
    end
  end

  describe "#deserialize" do
    it "deserializes ISO 8601 string to Time" do
      result = processor.deserialize("2025-01-15T10:30:00+09:00")
      expect(result.year).to eq(2025)
      expect(result.month).to eq(1)
      expect(result.day).to eq(15)
      expect(result.hour).to eq(10)
      expect(result.min).to eq(30)
      expect(result.sec).to eq(0)
      expect(result.utc_offset).to eq(9 * 3600)
    end

    it "deserializes UTC time string" do
      result = processor.deserialize("2025-01-15T10:30:00Z")
      expect(result.utc?).to be true
    end

    it "returns Time as-is" do
      time = Time.now
      expect(processor.deserialize(time)).to eq(time)
    end

    it "raises error for invalid time string" do
      expect { processor.deserialize("invalid") }.to raise_error(
        Skit::Serialization::DeserializeError,
        /Failed to deserialize Time/
      )
    end

    it "raises error for non-Time/String values" do
      expect { processor.deserialize(123) }.to raise_error(
        Skit::Serialization::DeserializeError,
        "Expected Time or String, got Integer"
      )
      expect { processor.deserialize(nil) }.to raise_error(
        Skit::Serialization::DeserializeError,
        "Expected Time or String, got NilClass"
      )
    end
  end
end
