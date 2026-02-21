# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Skit::Serialization::Processor::Symbol, type: :unit do
  let(:registry) { Skit::Serialization::Registry.new }
  let(:processor) { described_class.new(Symbol, registry: registry) }

  describe ".handles?" do
    it "returns true for Symbol class" do
      expect(described_class.handles?(Symbol)).to be true
    end

    it "returns false for other types" do
      expect(described_class.handles?(String)).to be false
      expect(described_class.handles?(Integer)).to be false
    end
  end

  describe "#serialize" do
    it "serializes symbol to string" do
      expect(processor.serialize(:hello)).to eq("hello")
    end

    it "raises error for non-symbol values" do
      expect { processor.serialize("hello") }.to raise_error(
        Skit::Serialization::SerializeError,
        "Expected Symbol, got String"
      )
      expect { processor.serialize(123) }.to raise_error(
        Skit::Serialization::SerializeError,
        "Expected Symbol, got Integer"
      )
      expect { processor.serialize(nil) }.to raise_error(
        Skit::Serialization::SerializeError,
        "Expected Symbol, got NilClass"
      )
    end
  end

  describe "#deserialize" do
    it "deserializes string to symbol" do
      expect(processor.deserialize("hello")).to eq(:hello)
    end

    it "returns symbol as-is" do
      expect(processor.deserialize(:hello)).to eq(:hello)
    end

    it "raises error for non-string/symbol values" do
      expect { processor.deserialize(123) }.to raise_error(
        Skit::Serialization::DeserializeError,
        "Expected String or Symbol, got Integer"
      )
      expect { processor.deserialize(nil) }.to raise_error(
        Skit::Serialization::DeserializeError,
        "Expected String or Symbol, got NilClass"
      )
    end
  end
end
