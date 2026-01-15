# typed: false
# frozen_string_literal: true

require "spec_helper"
require "active_model"

module SkitValidatorTestClasses
  class Address < T::Struct
    include ActiveModel::Validations

    const :city, String
    const :zip, String

    validates :city, presence: true
    validates :zip, format: { with: /\A\d{3}-\d{4}\z/, message: "must be in format XXX-XXXX" }
  end

  class Person < T::Struct
    include ActiveModel::Validations

    const :name, String
    const :age, Integer
    const :address, Address

    validates :name, presence: true
    validates :age, numericality: { greater_than: 0 }
  end

  class Order
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :person, Skit::Attribute[Person]

    validates :person, skit: true
  end
end

RSpec.describe ActiveModel::Validations::SkitValidator, type: :unit do
  describe "#validate_each" do
    context "with valid nested struct" do
      it "does not add errors" do
        address = SkitValidatorTestClasses::Address.new(city: "Tokyo", zip: "100-0001")
        person = SkitValidatorTestClasses::Person.new(name: "Alice", age: 30, address: address)
        order = SkitValidatorTestClasses::Order.new(person: person)

        expect(order).to be_valid
        expect(order.errors).to be_empty
      end
    end

    context "with invalid nested struct" do
      it "adds errors from nested validation" do
        address = SkitValidatorTestClasses::Address.new(city: "", zip: "invalid")
        person = SkitValidatorTestClasses::Person.new(name: "", age: -1, address: address)
        order = SkitValidatorTestClasses::Order.new(person: person)

        expect(order).not_to be_valid
        expect(order.errors["person.name"]).to include("can't be blank")
        expect(order.errors["person.age"]).to include("must be greater than 0")
        expect(order.errors["person.address.city"]).to include("can't be blank")
        expect(order.errors["person.address.zip"]).to include("must be in format XXX-XXXX")
      end
    end

    context "with nil value" do
      it "does not add errors" do
        order = SkitValidatorTestClasses::Order.new(person: nil)

        # Validator skips nil values (use presence validation separately if needed)
        expect(order.errors["person"]).to be_empty
      end
    end
  end
end
