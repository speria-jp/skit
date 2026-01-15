# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Skit::Serialization::Processor::Boolean, type: :unit do
  let(:registry) { Skit::Serialization::Registry.new }
  let(:processor) { described_class.new(T::Boolean, registry: registry) }

  describe ".handles?" do
    it "returns true for T::Boolean" do
      expect(described_class.handles?(T::Boolean)).to be true
    end

    it "returns false for other types" do
      expect(described_class.handles?(TrueClass)).to be false
      expect(described_class.handles?(FalseClass)).to be false
      expect(described_class.handles?(String)).to be false
    end
  end

  describe "#serialize" do
    it "serializes true to true" do
      expect(processor.serialize(true)).to be true
    end

    it "serializes false to false" do
      expect(processor.serialize(false)).to be false
    end

    it "raises error for non-boolean values" do
      expect { processor.serialize(1) }.to raise_error(
        Skit::Serialization::TypeMismatchError,
        "Expected TrueClass or FalseClass, got Integer"
      )
      expect { processor.serialize("true") }.to raise_error(
        Skit::Serialization::TypeMismatchError,
        "Expected TrueClass or FalseClass, got String"
      )
      expect { processor.serialize(nil) }.to raise_error(
        Skit::Serialization::TypeMismatchError,
        "Expected TrueClass or FalseClass, got NilClass"
      )
    end
  end

  describe "#deserialize" do
    it "deserializes true to true" do
      expect(processor.deserialize(true)).to be true
    end

    it "deserializes false to false" do
      expect(processor.deserialize(false)).to be false
    end

    it "raises error for non-boolean values" do
      expect { processor.deserialize(1) }.to raise_error(
        Skit::Serialization::DeserializationError,
        "Expected TrueClass or FalseClass, got Integer"
      )
      expect { processor.deserialize("true") }.to raise_error(
        Skit::Serialization::DeserializationError,
        "Expected TrueClass or FalseClass, got String"
      )
      expect { processor.deserialize(nil) }.to raise_error(
        Skit::Serialization::DeserializationError,
        "Expected TrueClass or FalseClass, got NilClass"
      )
    end
  end
end
