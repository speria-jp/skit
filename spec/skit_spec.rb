# typed: false
# frozen_string_literal: true

module SkitSpecTestClasses
  class Dog < T::Struct
    const :name, String
    const :breed, String
  end

  class Cat < T::Struct
    const :name, String
    const :indoor, T::Boolean
  end
end

RSpec.describe Skit do
  it "has a version number" do
    expect(Skit::VERSION).not_to be_nil
  end

  describe ".deserialize" do
    it "accepts union type" do
      union_type = T::Utils.coerce(T.any(SkitSpecTestClasses::Dog, SkitSpecTestClasses::Cat))
      result = described_class.deserialize({ "name" => "Buddy", "breed" => "Labrador" }, union_type)
      expect(result).to be_a(SkitSpecTestClasses::Dog)
      expect(result.name).to eq("Buddy")
    end
  end
end
