# typed: false
# frozen_string_literal: true

require "spec_helper"

# Test subclasses with different VALUE types - defined outside RSpec block
module ConstSpecTestClasses
  class StringConst < Skit::JsonSchema::Types::Const
    VALUE = "dog"
  end

  class IntegerConst < Skit::JsonSchema::Types::Const
    VALUE = 123
  end

  class FloatConst < Skit::JsonSchema::Types::Const
    VALUE = 1.5
  end

  class TrueConst < Skit::JsonSchema::Types::Const
    VALUE = true
  end

  class FalseConst < Skit::JsonSchema::Types::Const
    VALUE = false
  end
end

RSpec.describe Skit::JsonSchema::Types::Const do
  let(:string_const_class) { ConstSpecTestClasses::StringConst }
  let(:integer_const_class) { ConstSpecTestClasses::IntegerConst }
  let(:float_const_class) { ConstSpecTestClasses::FloatConst }
  let(:true_const_class) { ConstSpecTestClasses::TrueConst }
  let(:false_const_class) { ConstSpecTestClasses::FalseConst }

  describe ".value" do
    it "returns the VALUE constant for string const" do
      expect(string_const_class.value).to eq("dog")
    end

    it "returns the VALUE constant for integer const" do
      expect(integer_const_class.value).to eq(123)
    end

    it "returns the VALUE constant for float const" do
      expect(float_const_class.value).to eq(1.5)
    end

    it "returns the VALUE constant for true const" do
      expect(true_const_class.value).to be(true)
    end

    it "returns the VALUE constant for false const" do
      expect(false_const_class.value).to be(false)
    end
  end

  describe "#value" do
    it "returns the VALUE constant for instance" do
      instance = string_const_class.new
      expect(instance.value).to eq("dog")
    end

    it "returns integer VALUE for integer const instance" do
      instance = integer_const_class.new
      expect(instance.value).to eq(123)
    end
  end

  describe "#==" do
    it "returns true for instances of the same class" do
      instance1 = string_const_class.new
      instance2 = string_const_class.new
      expect(instance1 == instance2).to be(true)
    end

    it "returns false for instances of different classes" do
      string_instance = string_const_class.new
      integer_instance = integer_const_class.new
      expect(string_instance == integer_instance).to be(false)
    end

    it "returns false when compared with the raw value" do
      instance = string_const_class.new
      expect(instance == "dog").to be(false)
    end

    it "returns false when compared with nil" do
      instance = string_const_class.new
      expect(instance.nil?).to be(false)
    end
  end

  describe "#eql?" do
    it "returns true for instances of the same class" do
      instance1 = string_const_class.new
      instance2 = string_const_class.new
      expect(instance1.eql?(instance2)).to be(true)
    end

    it "returns false for instances of different classes" do
      string_instance = string_const_class.new
      integer_instance = integer_const_class.new
      expect(string_instance.eql?(integer_instance)).to be(false)
    end
  end

  describe "#hash" do
    it "returns the same hash for instances of the same class" do
      instance1 = string_const_class.new
      instance2 = string_const_class.new
      expect(instance1.hash).to eq(instance2.hash)
    end

    it "can be used as Hash key" do
      instance1 = string_const_class.new
      instance2 = string_const_class.new

      hash = { instance1 => "value" }
      expect(hash[instance2]).to eq("value")
    end
  end

  describe "#inspect" do
    it "returns a readable string representation" do
      instance = string_const_class.new
      expect(instance.inspect).to include("dog")
    end
  end

  describe "#to_s" do
    it "returns the value as string" do
      instance = string_const_class.new
      expect(instance.to_s).to eq("dog")
    end

    it "converts integer value to string" do
      instance = integer_const_class.new
      expect(instance.to_s).to eq("123")
    end
  end

  describe "case/when usage" do
    it "works with case/when using class" do
      instance = string_const_class.new

      result = case instance
               when string_const_class then "matched string"
               when integer_const_class then "matched integer"
               else "no match"
               end

      expect(result).to eq("matched string")
    end

    it "matches the correct class in union-like scenario" do
      instances = [string_const_class.new, integer_const_class.new]

      results = instances.map do |instance|
        case instance
        when string_const_class then "dog"
        when integer_const_class then "number"
        else "unknown"
        end
      end

      expect(results).to eq(%w[dog number])
    end
  end
end
