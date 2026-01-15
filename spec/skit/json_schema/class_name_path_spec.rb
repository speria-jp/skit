# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Skit::JsonSchema::ClassNamePath, type: :unit do
  describe ".title_to_class_name" do
    it "converts simple title" do
      result = described_class.title_to_class_name("User")

      expect(result.to_class_name).to eq("User")
    end

    it "converts title with spaces" do
      result = described_class.title_to_class_name("User Profile")

      expect(result.to_class_name).to eq("UserProfile")
    end

    it "converts PascalCase title" do
      result = described_class.title_to_class_name("APIResponseData")

      expect(result.to_class_name).to eq("ApiResponseData")
    end

    it "converts title with special characters" do
      result = described_class.title_to_class_name("API Response Data v2!")

      expect(result.to_class_name).to eq("ApiResponseDataV2")
    end

    it "returns default for empty title" do
      result = described_class.title_to_class_name("   ")

      expect(result.to_class_name).to eq("GeneratedClass")
    end
  end

  describe ".from_file_path" do
    it "converts snake_case file name" do
      result = described_class.from_file_path("user_profile.json")

      expect(result.to_class_name).to eq("UserProfile")
    end

    it "returns default for nil path" do
      result = described_class.from_file_path(nil)

      expect(result.to_class_name).to eq("GeneratedClass")
    end
  end

  describe ".default" do
    it "returns GeneratedClass" do
      result = described_class.default

      expect(result.to_class_name).to eq("GeneratedClass")
    end
  end

  describe "#append" do
    it "appends part to path" do
      path = described_class.new(["User"])
      result = path.append("address")

      expect(result.to_class_name).to eq("UserAddress")
    end

    it "converts snake_case to PascalCase" do
      path = described_class.new(["User"])
      result = path.append("home_address")

      expect(result.to_class_name).to eq("UserHomeAddress")
    end
  end

  describe "#to_class_name" do
    it "joins parts" do
      path = described_class.new(%w[User Profile Settings])

      expect(path.to_class_name).to eq("UserProfileSettings")
    end
  end
end
