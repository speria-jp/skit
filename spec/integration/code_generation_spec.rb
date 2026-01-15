# typed: false
# frozen_string_literal: true

# rubocop:disable RSpec/DescribeClass, Security/Eval
require "spec_helper"

RSpec.describe "JSON Schema to T::Struct code generation", type: :integration do
  describe "generate and use T::Struct from JSON Schema" do
    let(:user_schema) do
      {
        "type" => "object",
        "title" => "User",
        "properties" => {
          "name" => { "type" => "string" },
          "age" => { "type" => "integer" },
          "email" => { "type" => "string" },
          "balance" => { "type" => "number" },
          "tags" => {
            "type" => "array",
            "items" => { "type" => "string" }
          },
          "address" => {
            "type" => "object",
            "properties" => {
              "city" => { "type" => "string" },
              "zip" => { "type" => "string" }
            },
            "required" => ["city"]
          }
        },
        "required" => %w[name email]
      }
    end

    it "generates valid Ruby code from JSON Schema and allows serialization" do
      code = Skit::JsonSchema.generate(user_schema, class_name: "User", module_name: "Generated")

      expect(code).to include("module Generated")
      expect(code).to include("class User < T::Struct")
      expect(code).to include("prop :name, String")
      expect(code).to include("prop :email, String")

      eval(code)

      user_data = {
        "name" => "Alice",
        "email" => "alice@example.com",
        "age" => 30,
        "balance" => 1000.5,
        "tags" => %w[ruby sorbet],
        "address" => { "city" => "Tokyo", "zip" => "100-0001" }
      }

      user = Skit.deserialize(user_data, Generated::User)

      expect(user).to be_a(Generated::User)
      expect(user.name).to eq("Alice")
      expect(user.email).to eq("alice@example.com")
      expect(user.age).to eq(30)
      expect(user.balance).to eq(1000.5)
      expect(user.tags).to eq(%w[ruby sorbet])
      expect(user.address).to be_a(Generated::UserAddress)
      expect(user.address.city).to eq("Tokyo")
      expect(user.address.zip).to eq("100-0001")

      serialized = Skit.serialize(user)

      expect(serialized).to eq(user_data)
    end
  end

  describe "generate and use nested T::Struct from JSON Schema" do
    let(:order_schema) do
      {
        "type" => "object",
        "title" => "Order",
        "properties" => {
          "id" => { "type" => "integer" },
          "items" => {
            "type" => "array",
            "items" => {
              "type" => "object",
              "properties" => {
                "product" => { "type" => "string" },
                "quantity" => { "type" => "integer" },
                "price" => { "type" => "number" }
              },
              "required" => %w[product quantity]
            }
          },
          "shipping" => {
            "type" => "object",
            "properties" => {
              "shipping_method" => { "type" => "string" },
              "address" => {
                "type" => "object",
                "properties" => {
                  "street" => { "type" => "string" },
                  "city" => { "type" => "string" },
                  "country" => { "type" => "string" }
                },
                "required" => %w[city country]
              }
            },
            "required" => ["shipping_method"]
          }
        },
        "required" => ["id"]
      }
    end

    it "handles deeply nested structures" do
      code = Skit::JsonSchema.generate(order_schema, class_name: "Order", module_name: "OrderModule")

      eval(code)

      order_data = {
        "id" => 123,
        "items" => [
          { "product" => "Widget", "quantity" => 2, "price" => 9.99 },
          { "product" => "Gadget", "quantity" => 1, "price" => 29.99 }
        ],
        "shipping" => {
          "shipping_method" => "express",
          "address" => {
            "street" => "123 Main St",
            "city" => "New York",
            "country" => "USA"
          }
        }
      }

      order = Skit.deserialize(order_data, OrderModule::Order)

      expect(order.id).to eq(123)
      expect(order.items.size).to eq(2)
      expect(order.items[0].product).to eq("Widget")
      expect(order.items[0].quantity).to eq(2)
      expect(order.items[0].price).to eq(9.99)
      expect(order.shipping.shipping_method).to eq("express")
      expect(order.shipping.address.city).to eq("New York")

      serialized = Skit.serialize(order)

      expect(serialized).to eq(order_data)
    end
  end

  describe "date handling" do
    let(:event_schema) do
      {
        "type" => "object",
        "title" => "Event",
        "properties" => {
          "name" => { "type" => "string" },
          "date" => { "type" => "string", "format" => "date" }
        },
        "required" => %w[name date]
      }
    end

    it "handles date format" do
      code = Skit::JsonSchema.generate(event_schema, class_name: "Event", module_name: "EventModule")

      eval(code)

      event_data = {
        "name" => "Conference",
        "date" => "2025-06-15"
      }

      event = Skit.deserialize(event_data, EventModule::Event)

      expect(event.name).to eq("Conference")
      expect(event.date).to be_a(Date)
      expect(event.date.to_s).to eq("2025-06-15")

      serialized = Skit.serialize(event)

      expect(serialized["name"]).to eq("Conference")
      expect(serialized["date"]).to eq("2025-06-15")
    end
  end

  describe "code generation options" do
    let(:simple_schema) do
      {
        "type" => "object",
        "properties" => {
          "name" => { "type" => "string" }
        },
        "required" => ["name"]
      }
    end

    it "generates code with custom class and module name" do
      code = Skit::JsonSchema.generate(simple_schema, class_name: "MyClass", module_name: "MyModule")

      expect(code).to include("module MyModule")
      expect(code).to include("class MyClass < T::Struct")
      expect(code).to include("prop :name, String")
    end

    it "generates code without module when module_name is not specified" do
      code = Skit::JsonSchema.generate(simple_schema, class_name: "SimpleClass")

      expect(code).to include("class SimpleClass < T::Struct")
      expect(code).not_to include("module ")
    end
  end
end
# rubocop:enable RSpec/DescribeClass, Security/Eval
