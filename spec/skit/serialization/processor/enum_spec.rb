# typed: false
# frozen_string_literal: true

require "spec_helper"

# Test enum class
class TestStatus < T::Enum
  enums do
    Active = new("active")
    Inactive = new("inactive")
    Pending = new("pending")
  end
end

# Test enum with integer values
class TestPriority < T::Enum
  enums do
    Low = new(1)
    Medium = new(2)
    High = new(3)
  end
end

RSpec.describe Skit::Serialization::Processor::Enum, type: :unit do
  let(:registry) { Skit::Serialization.default_registry }
  let(:string_enum_processor) { described_class.new(TestStatus, registry: registry) }
  let(:int_enum_processor) { described_class.new(TestPriority, registry: registry) }

  describe ".handles?" do
    it "returns true for T::Enum subclass" do
      expect(described_class.handles?(TestStatus)).to be(true)
    end

    it "returns true for T::Enum subclass with integer values" do
      expect(described_class.handles?(TestPriority)).to be(true)
    end

    it "returns false for non-Enum classes" do
      expect(described_class.handles?(String)).to be(false)
      expect(described_class.handles?(Integer)).to be(false)
    end

    it "returns false for non-class values" do
      expect(described_class.handles?("active")).to be(false)
      expect(described_class.handles?(nil)).to be(false)
    end
  end

  describe "#serialize" do
    context "with string enum" do
      it "serializes enum to its string value" do
        expect(string_enum_processor.serialize(TestStatus::Active)).to eq("active")
        expect(string_enum_processor.serialize(TestStatus::Inactive)).to eq("inactive")
        expect(string_enum_processor.serialize(TestStatus::Pending)).to eq("pending")
      end
    end

    context "with integer enum" do
      it "serializes enum to its integer value" do
        expect(int_enum_processor.serialize(TestPriority::Low)).to eq(1)
        expect(int_enum_processor.serialize(TestPriority::Medium)).to eq(2)
        expect(int_enum_processor.serialize(TestPriority::High)).to eq(3)
      end
    end

    it "raises error for non-enum values" do
      expect do
        string_enum_processor.serialize("active")
      end.to raise_error(Skit::Serialization::SerializeError, /Expected TestStatus/)
    end
  end

  describe "#deserialize" do
    context "with string enum" do
      it "deserializes string to enum instance" do
        expect(string_enum_processor.deserialize("active")).to eq(TestStatus::Active)
        expect(string_enum_processor.deserialize("inactive")).to eq(TestStatus::Inactive)
        expect(string_enum_processor.deserialize("pending")).to eq(TestStatus::Pending)
      end
    end

    context "with integer enum" do
      it "deserializes integer to enum instance" do
        expect(int_enum_processor.deserialize(1)).to eq(TestPriority::Low)
        expect(int_enum_processor.deserialize(2)).to eq(TestPriority::Medium)
        expect(int_enum_processor.deserialize(3)).to eq(TestPriority::High)
      end
    end

    it "returns enum as-is if already an enum instance" do
      expect(string_enum_processor.deserialize(TestStatus::Active)).to eq(TestStatus::Active)
    end

    it "raises error for invalid value" do
      expect do
        string_enum_processor.deserialize("invalid")
      end.to raise_error(Skit::Serialization::DeserializeError, /Invalid value "invalid" for TestStatus/)
    end
  end
end
