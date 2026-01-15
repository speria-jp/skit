# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Skit::JsonSchema, type: :unit do
  describe ".generate" do
    let(:schema) do
      {
        "type" => "object",
        "properties" => {
          "name" => { "type" => "string" },
          "age" => { "type" => "integer" }
        },
        "required" => ["name"]
      }
    end

    it "generates Sorbet T::Struct code" do
      result = described_class.generate(schema, class_name: "User")

      expect(result).to include("# typed: strict")
      expect(result).to include("class User < T::Struct")
      expect(result).to include("prop :name, String")
      expect(result).to include("prop :age, T.nilable(Integer)")
    end

    it "accepts string keys in options" do
      result = described_class.generate(schema, "class_name" => "Person")

      expect(result).to include("class Person < T::Struct")
    end

    it "uses default class name when not specified" do
      result = described_class.generate(schema)

      expect(result).to include("class GeneratedClass < T::Struct")
    end

    it "supports module_name option" do
      result = described_class.generate(schema, class_name: "User", module_name: "MyApp")

      expect(result).to include("module MyApp")
      expect(result).to include("  class User < T::Struct")
    end

    it "supports typed_strictness option" do
      result = described_class.generate(schema, typed_strictness: "false")

      expect(result).to include("# typed: false")
    end
  end
end
