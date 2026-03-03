# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Skit::Serialization::Path, type: :unit do
  describe "#initialize" do
    it "creates an empty path by default" do
      path = described_class.new
      expect(path).to be_empty
      expect(path.segments).to eq([])
    end

    it "creates a path with initial segments" do
      path = described_class.new(["items", 2, "name"])
      expect(path.segments).to eq(["items", 2, "name"])
    end
  end

  describe "#append" do
    it "returns a new Path with the segment appended" do
      path = described_class.new
      new_path = path.append("items")
      expect(new_path.segments).to eq(["items"])
      expect(path.segments).to eq([])
    end

    it "chains property segments with append" do
      path = described_class.new
                            .append("address")
                            .append("city")
      expect(path.segments).to eq(%w[address city])
    end

    it "appends integer segments for array indices" do
      path = described_class.new
                            .append("items")
                            .append(2)
                            .append("name")
      expect(path.segments).to eq(["items", 2, "name"])
    end
  end

  describe "#empty?" do
    it "returns true for empty path" do
      expect(described_class.new).to be_empty
    end

    it "returns false for non-empty path" do
      expect(described_class.new.append("foo")).not_to be_empty
    end
  end

  describe "#to_s" do
    it "returns empty string for empty path" do
      expect(described_class.new.to_s).to eq("")
    end

    it "returns property name for single property" do
      path = described_class.new.append("name")
      expect(path.to_s).to eq("name")
    end

    it "joins properties with dots" do
      path = described_class.new
                            .append("address")
                            .append("city")
      expect(path.to_s).to eq("address.city")
    end

    it "uses bracket notation for array indices" do
      path = described_class.new
                            .append("items")
                            .append(0)
      expect(path.to_s).to eq("items[0]")
    end

    it "handles complex nested paths" do
      path = described_class.new
                            .append("items")
                            .append(1)
                            .append("product")
                            .append("name")
      expect(path.to_s).to eq("items[1].product.name")
    end

    it "handles consecutive array indices" do
      path = described_class.new
                            .append("matrix")
                            .append(0)
                            .append(1)
      expect(path.to_s).to eq("matrix[0][1]")
    end
  end

  describe "#to_json_pointer" do
    it "returns empty string for empty path" do
      expect(described_class.new.to_json_pointer).to eq("")
    end

    it "returns JSON Pointer for single property" do
      path = described_class.new.append("name")
      expect(path.to_json_pointer).to eq("/name")
    end

    it "returns JSON Pointer for nested path" do
      path = described_class.new
                            .append("address")
                            .append("city")
      expect(path.to_json_pointer).to eq("/address/city")
    end

    it "returns JSON Pointer with array index" do
      path = described_class.new
                            .append("items")
                            .append(2)
      expect(path.to_json_pointer).to eq("/items/2")
    end

    it "escapes tilde in segment" do
      path = described_class.new.append("a~b")
      expect(path.to_json_pointer).to eq("/a~0b")
    end

    it "escapes slash in segment" do
      path = described_class.new.append("a/b")
      expect(path.to_json_pointer).to eq("/a~1b")
    end
  end

  describe "#==" do
    it "considers equal paths as equal" do
      a = described_class.new(["items", 0, "name"])
      b = described_class.new(["items", 0, "name"])
      expect(a).to eq(b)
    end

    it "considers different paths as not equal" do
      a = described_class.new(["items", 0])
      b = described_class.new(["items", 1])
      expect(a).not_to eq(b)
    end

    it "considers empty paths as equal" do
      a = described_class.new
      b = described_class.new
      expect(a).to eq(b)
    end

    it "is not equal to non-Path objects" do
      expect(described_class.new).not_to eq("")
    end
  end

  describe "#hash and #eql?" do
    it "can be used as hash key" do
      a = described_class.new(["items", 0])
      b = described_class.new(["items", 0])
      h = { a => "value" }
      expect(h[b]).to eq("value")
    end
  end
end
