# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Skit::Serialization::Processor::String, type: :unit do
  let(:registry) { Skit::Serialization::Registry.new }
  let(:processor) { described_class.new(String, registry: registry) }

  describe ".handles?" do
    it "returns true for String class" do
      expect(described_class.handles?(String)).to be true
    end

    it "returns false for other types" do
      expect(described_class.handles?(Integer)).to be false
      expect(described_class.handles?(Float)).to be false
    end
  end

  describe "#serialize" do
    it "serializes string to string" do
      expect(processor.serialize("hello")).to eq("hello")
    end

    it "raises error for non-string values" do
      expect { processor.serialize(123) }.to raise_error(
        Skit::Serialization::SerializeError,
        "Expected String, got Integer"
      )
      expect { processor.serialize(:symbol) }.to raise_error(
        Skit::Serialization::SerializeError,
        "Expected String, got Symbol"
      )
      expect { processor.serialize(nil) }.to raise_error(
        Skit::Serialization::SerializeError,
        "Expected String, got NilClass"
      )
    end
  end

  describe "#deserialize" do
    it "deserializes string to string" do
      expect(processor.deserialize("hello")).to eq("hello")
    end

    it "raises error for non-string values" do
      expect { processor.deserialize(123) }.to raise_error(
        Skit::Serialization::DeserializeError,
        "Expected String, got Integer"
      )
      expect { processor.deserialize(:symbol) }.to raise_error(
        Skit::Serialization::DeserializeError,
        "Expected String, got Symbol"
      )
      expect { processor.deserialize(nil) }.to raise_error(
        Skit::Serialization::DeserializeError,
        "Expected String, got NilClass"
      )
    end
  end
end
