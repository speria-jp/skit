# typed: false
# frozen_string_literal: true

require "spec_helper"

module ErrorPathSpecTestClasses
  class Address < T::Struct
    const :city, String
    const :zip, String
  end

  class Item < T::Struct
    const :name, String
    const :price, Integer
  end

  class Order < T::Struct
    const :id, Integer
    const :items, T::Array[Item]
    const :shipping_address, Address
  end

  class Catalog < T::Struct
    const :products, T::Hash[String, Item]
  end
end

RSpec.describe Skit::Serialization::Error, type: :unit do
  let(:registry) { Skit::Serialization.default_registry }

  describe "serialize errors" do
    context "when error occurs at root level" do
      it "has empty path for root-level type mismatch" do
        processor = registry.processor_for(ErrorPathSpecTestClasses::Item)
        error = nil
        begin
          processor.serialize("not a struct")
        rescue Skit::Serialization::SerializeError => e
          error = e
        end

        expect(error).not_to be_nil
        expect(error.path).to be_empty
        expect(error.message).not_to include("(at")
      end
    end

    context "when error occurs in nested struct" do
      it "includes path for nested property type mismatch" do
        processor = registry.processor_for(String)
        error = nil
        begin
          processor.serialize(123, path: Skit::Serialization::Path.new(%w[shipping_address city]))
        rescue Skit::Serialization::SerializeError => e
          error = e
        end

        expect(error.path).to eq(Skit::Serialization::Path.new(%w[shipping_address city]))
        expect(error.message).to include("(at shipping_address.city)")
      end
    end

    context "when error occurs in array elements" do
      it "includes array index in path" do
        processor = registry.processor_for(T::Utils.coerce(T::Array[String]))
        error = nil
        begin
          processor.serialize(["valid", 123], path: Skit::Serialization::Path.new(["items"]))
        rescue Skit::Serialization::SerializeError => e
          error = e
        end

        expect(error.path).to eq(Skit::Serialization::Path.new(["items", 1]))
        expect(error.message).to include("(at items[1])")
      end
    end

    context "with hash values" do
      it "includes hash key in path" do
        processor = registry.processor_for(T::Utils.coerce(T::Hash[String, Integer]))
        error = nil
        begin
          processor.serialize({ "a" => 1, "b" => "not_int" })
        rescue Skit::Serialization::SerializeError => e
          error = e
        end

        expect(error.path).to eq(Skit::Serialization::Path.new(["b"]))
        expect(error.message).to include("(at b)")
      end
    end
  end

  describe "deserialize errors" do
    context "when error occurs at root level" do
      it "has empty path for root-level type mismatch" do
        processor = registry.processor_for(ErrorPathSpecTestClasses::Item)
        error = nil
        begin
          processor.deserialize("not a hash")
        rescue Skit::Serialization::DeserializeError => e
          error = e
        end

        expect(error).not_to be_nil
        expect(error.path).to be_empty
        expect(error.message).to eq("Expected Hash, got String")
      end
    end

    context "when error occurs in nested struct" do
      it "includes path for nested property type mismatch" do
        processor = registry.processor_for(ErrorPathSpecTestClasses::Order)
        error = nil
        begin
          processor.deserialize({
                                  "id" => 1,
                                  "items" => [],
                                  "shipping_address" => "not a hash"
                                })
        rescue Skit::Serialization::DeserializeError => e
          error = e
        end

        expect(error.path).to eq(Skit::Serialization::Path.new(["shipping_address"]))
        expect(error.message).to include("(at shipping_address)")
      end
    end

    context "when error occurs in array elements" do
      it "includes array index in path" do
        processor = registry.processor_for(ErrorPathSpecTestClasses::Order)
        error = nil
        begin
          processor.deserialize({
                                  "id" => 1,
                                  "items" => [
                                    { "name" => "Widget", "price" => 100 },
                                    "not a hash"
                                  ],
                                  "shipping_address" => { "city" => "Tokyo", "zip" => "100-0001" }
                                })
        rescue Skit::Serialization::DeserializeError => e
          error = e
        end

        expect(error.path).to eq(Skit::Serialization::Path.new(["items", 1]))
        expect(error.message).to include("(at items[1])")
      end
    end

    context "when error is deeply nested" do
      it "includes full path for deeply nested errors" do
        processor = registry.processor_for(ErrorPathSpecTestClasses::Order)
        error = nil
        begin
          processor.deserialize({
                                  "id" => 1,
                                  "items" => [
                                    { "name" => "Widget", "price" => 100 },
                                    { "name" => 42, "price" => 200 }
                                  ],
                                  "shipping_address" => { "city" => "Tokyo", "zip" => "100-0001" }
                                })
        rescue Skit::Serialization::DeserializeError => e
          error = e
        end

        expect(error.path).to eq(Skit::Serialization::Path.new(["items", 1, "name"]))
        expect(error.message).to include("(at items[1].name)")
      end
    end

    context "with hash values" do
      it "includes hash key in path" do
        processor = registry.processor_for(ErrorPathSpecTestClasses::Catalog)
        error = nil
        begin
          processor.deserialize({
                                  "products" => {
                                    "widget" => { "name" => "Widget", "price" => 100 },
                                    "gadget" => "not a hash"
                                  }
                                })
        rescue Skit::Serialization::DeserializeError => e
          error = e
        end

        expect(error.path).to eq(Skit::Serialization::Path.new(%w[products gadget]))
        expect(error.message).to include("(at products.gadget)")
      end
    end
  end

  describe "error path attribute" do
    it "returns Path object from error" do
      processor = registry.processor_for(String)
      path = Skit::Serialization::Path.new(["items", 0, "name"])
      error = nil
      begin
        processor.serialize(123, path: path)
      rescue Skit::Serialization::SerializeError => e
        error = e
      end

      expect(error.path).to be_a(Skit::Serialization::Path)
      expect(error.path.segments).to eq(["items", 0, "name"])
      expect(error.path.to_json_pointer).to eq("/items/0/name")
    end
  end
end
