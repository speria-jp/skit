# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Skit::JsonSchema::Config, type: :unit do
  describe "#initialize" do
    context "with valid parameters" do
      it "creates config with default values" do
        config = described_class.new

        expect(config.class_name).to be_nil
        expect(config.module_name).to be_nil
        expect(config.typed_strictness).to eq("strict")
      end

      it "accepts valid class name" do
        config = described_class.new(class_name: "User")

        expect(config.class_name).to eq("User")
      end

      it "accepts valid module name" do
        config = described_class.new(module_name: "MyModule")

        expect(config.module_name).to eq("MyModule")
      end

      it "accepts nested module name" do
        config = described_class.new(module_name: "Foo::Bar::Baz")

        expect(config.module_name).to eq("Foo::Bar::Baz")
      end

      it "accepts valid typed_strictness" do
        config = described_class.new(typed_strictness: "ignore")

        expect(config.typed_strictness).to eq("ignore")
      end
    end

    context "with invalid parameters" do
      it "raises error for invalid class name starting with lowercase" do
        expect do
          described_class.new(class_name: "user")
        end.to raise_error(ArgumentError, /Invalid class name/)
      end

      it "raises error for class name with special characters" do
        expect do
          described_class.new(class_name: "User-Name")
        end.to raise_error(ArgumentError, /Invalid class name/)
      end

      it "raises error for invalid module name" do
        expect do
          described_class.new(module_name: "invalid-module")
        end.to raise_error(ArgumentError, /Invalid module name/)
      end

      it "raises error for invalid typed_strictness" do
        expect do
          described_class.new(typed_strictness: "invalid")
        end.to raise_error(ArgumentError, /Invalid typed strictness level/)
      end
    end
  end
end
