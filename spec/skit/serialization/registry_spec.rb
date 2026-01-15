# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Skit::Serialization::Registry, type: :unit do
  let(:registry) { described_class.new }

  before do
    test_integer_processor = Class.new(Skit::Serialization::Processor::Base) do
      define_singleton_method(:handles?) do |type_spec|
        klass = case type_spec
                when T::Types::Simple
                  type_spec.raw_type
                when Class
                  type_spec
                end
        klass == Integer
      end

      define_method(:serialize) do |value|
        value&.to_i
      end

      define_method(:deserialize) do |value|
        value&.to_i
      end
    end

    test_string_processor = Class.new(Skit::Serialization::Processor::Base) do
      define_singleton_method(:handles?) do |type_spec|
        klass = case type_spec
                when T::Types::Simple
                  type_spec.raw_type
                when Class
                  type_spec
                end
        klass == String
      end

      define_method(:serialize) do |value|
        value&.to_s
      end

      define_method(:deserialize) do |value|
        value&.to_s
      end
    end

    stub_const("TestInteger", test_integer_processor)
    stub_const("TestString", test_string_processor)
  end

  describe "#register" do
    it "registers a processor class" do
      registry.register(TestInteger)
      expect(registry.find_processor(Integer)).to eq(TestInteger)
    end

    it "maintains registration order" do
      registry.register(TestInteger)
      registry.register(TestString)

      expect(registry.find_processor(Integer)).to eq(TestInteger)
    end
  end

  describe "#find_processor" do
    before do
      registry.register(TestInteger)
      registry.register(TestString)
    end

    it "finds processor for Integer" do
      expect(registry.find_processor(Integer)).to eq(TestInteger)
    end

    it "finds processor for String" do
      expect(registry.find_processor(String)).to eq(TestString)
    end

    it "finds processor for T::Types::Simple" do
      type_spec = T::Utils.coerce(Integer)
      expect(registry.find_processor(type_spec)).to eq(TestInteger)
    end

    it "raises UnknownTypeError when no processor found" do
      expect { registry.find_processor(Float) }.to raise_error(
        Skit::Serialization::UnknownTypeError,
        /No processor for/
      )
    end
  end

  describe "#processor_for" do
    before do
      registry.register(TestInteger)
    end

    it "returns a processor instance" do
      processor = registry.processor_for(Integer)
      expect(processor).to be_a(TestInteger)
    end

    it "passes registry to processor" do
      processor = registry.processor_for(Integer)
      expect(processor.instance_variable_get(:@registry)).to eq(registry)
    end

    it "passes type_spec to processor" do
      processor = registry.processor_for(Integer)
      expect(processor.instance_variable_get(:@type_spec)).to eq(Integer)
    end
  end
end
