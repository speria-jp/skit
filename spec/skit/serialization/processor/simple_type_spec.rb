# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Skit::Serialization::Processor::SimpleType, type: :unit do
  let(:registry) { Skit::Serialization::Registry.new }
  let(:string_simple_type) { T::Utils.coerce(String) }
  let(:integer_simple_type) { T::Utils.coerce(Integer) }
  let(:processor) { described_class.new(string_simple_type, registry: registry) }

  before do
    registry.register(Skit::Serialization::Processor::String)
    registry.register(Skit::Serialization::Processor::Integer)
    registry.register(described_class)
  end

  describe ".handles?" do
    it "returns true for T::Types::Simple" do
      expect(described_class.handles?(string_simple_type)).to be true
      expect(described_class.handles?(integer_simple_type)).to be true
    end

    it "returns false for raw classes" do
      expect(described_class.handles?(String)).to be false
      expect(described_class.handles?(Integer)).to be false
    end

    it "returns false for other types" do
      expect(described_class.handles?(nil)).to be false
      expect(described_class.handles?("String")).to be false
    end
  end

  describe "#serialize" do
    it "delegates to the underlying type processor" do
      result = processor.serialize("hello")
      expect(result).to eq("hello")
    end

    it "raises error for type mismatch" do
      expect { processor.serialize(123) }.to raise_error(
        Skit::Serialization::SerializeError,
        /Expected String/
      )
    end
  end

  describe "#deserialize" do
    it "delegates to the underlying type processor" do
      result = processor.deserialize("hello")
      expect(result).to eq("hello")
    end

    it "works with Integer type" do
      int_processor = described_class.new(integer_simple_type, registry: registry)
      result = int_processor.deserialize(42)
      expect(result).to eq(42)
    end
  end
end
