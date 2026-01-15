# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Skit::Serialization::Processor::Base, type: :unit do
  before do
    test_processor = Class.new(described_class)
    stub_const("TestProcessor", test_processor)
  end

  describe ".handles?" do
    it "raises NotImplementedError when not overridden" do
      expect { TestProcessor.handles?(Integer) }.to raise_error(NotImplementedError)
    end
  end

  describe "#serialize" do
    it "raises NotImplementedError when not overridden" do
      registry = Skit::Serialization::Registry.new
      processor = TestProcessor.new(Integer, registry: registry)
      expect { processor.serialize(123) }.to raise_error(NotImplementedError)
    end
  end

  describe "#deserialize" do
    it "raises NotImplementedError when not overridden" do
      registry = Skit::Serialization::Registry.new
      processor = TestProcessor.new(Integer, registry: registry)
      expect { processor.deserialize(123) }.to raise_error(NotImplementedError)
    end
  end

  describe "#traverse" do
    it "calls block with type_spec, node, and path" do
      concrete_class = Class.new(described_class) do
        define_method(:serialize) do |value|
          value
        end

        define_method(:deserialize) do |value|
          value
        end
      end
      stub_const("ConcreteProcessor", concrete_class)

      registry = Skit::Serialization::Registry.new
      processor = ConcreteProcessor.new(String, registry: registry)

      called_with = []
      processor.traverse("test value", path: "some.path") do |type_spec, node, path|
        called_with << [type_spec, node, path]
      end

      expect(called_with).to eq([[String, "test value", "some.path"]])
    end
  end
end
