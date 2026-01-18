# typed: false
# frozen_string_literal: true

# rubocop:disable RSpec/DescribeClass, Security/Eval
require "spec_helper"

RSpec.describe "JSON Schema enum support", type: :integration do
  describe "string enum" do
    let(:schema) do
      {
        "type" => "object",
        "title" => "Task",
        "properties" => {
          "title" => { "type" => "string" },
          "status" => {
            "type" => "string",
            "enum" => %w[pending in_progress completed]
          }
        },
        "required" => %w[title status]
      }
    end

    it "generates T::Enum class and allows serialization/deserialization" do
      code = Skit::JsonSchema.generate(schema, module_name: "EnumTest1")

      expect(code).to include("class Status < T::Enum")
      expect(code).to include("enums do")
      expect(code).to include('Pending = new("pending")')
      expect(code).to include('InProgress = new("in_progress")')
      expect(code).to include('Completed = new("completed")')
      expect(code).to include("prop :status, Status")

      eval(code)

      task_data = {
        "title" => "Write tests",
        "status" => "in_progress"
      }

      task = Skit.deserialize(task_data, EnumTest1::Task)

      expect(task).to be_a(EnumTest1::Task)
      expect(task.title).to eq("Write tests")
      expect(task.status).to eq(EnumTest1::Status::InProgress)
      expect(task.status.serialize).to eq("in_progress")

      serialized = Skit.serialize(task)

      expect(serialized).to eq(task_data)
    end

    it "raises error for invalid enum value" do
      code = Skit::JsonSchema.generate(schema, module_name: "EnumTest2")
      eval(code)

      invalid_data = {
        "title" => "Invalid task",
        "status" => "unknown"
      }

      expect do
        Skit.deserialize(invalid_data, EnumTest2::Task)
      end.to raise_error(Skit::Serialization::DeserializationError, /Invalid value "unknown" for EnumTest2::Status/)
    end
  end

  describe "integer enum" do
    let(:schema) do
      {
        "type" => "object",
        "title" => "Priority",
        "properties" => {
          "name" => { "type" => "string" },
          "level" => {
            "type" => "integer",
            "enum" => [1, 2, 3]
          }
        },
        "required" => %w[name level]
      }
    end

    it "generates T::Enum class with integer values" do
      code = Skit::JsonSchema.generate(schema, module_name: "EnumTest3")

      expect(code).to include("class Level < T::Enum")
      expect(code).to include("Val1 = new(1)")
      expect(code).to include("Val2 = new(2)")
      expect(code).to include("Val3 = new(3)")

      eval(code)

      priority_data = {
        "name" => "High Priority",
        "level" => 3
      }

      priority = Skit.deserialize(priority_data, EnumTest3::Priority)

      expect(priority.name).to eq("High Priority")
      expect(priority.level).to eq(EnumTest3::Level::Val3)
      expect(priority.level.serialize).to eq(3)

      serialized = Skit.serialize(priority)

      expect(serialized).to eq(priority_data)
    end
  end

  describe "optional enum property" do
    let(:schema) do
      {
        "type" => "object",
        "title" => "OptionalEnum",
        "properties" => {
          "name" => { "type" => "string" },
          "category" => {
            "type" => "string",
            "enum" => %w[a b c]
          }
        },
        "required" => ["name"]
      }
    end

    it "handles nil for optional enum property" do
      code = Skit::JsonSchema.generate(schema, module_name: "EnumTest4")

      expect(code).to include("prop :category, T.nilable(Category)")

      eval(code)

      data_without_category = {
        "name" => "Test"
      }

      obj = Skit.deserialize(data_without_category, EnumTest4::OptionalEnum)

      expect(obj.name).to eq("Test")
      expect(obj.category).to be_nil

      serialized = Skit.serialize(obj)

      expect(serialized).to eq({ "name" => "Test", "category" => nil })
    end

    it "handles present optional enum property" do
      code = Skit::JsonSchema.generate(schema, module_name: "EnumTest5")
      eval(code)

      data_with_category = {
        "name" => "Test",
        "category" => "b"
      }

      obj = Skit.deserialize(data_with_category, EnumTest5::OptionalEnum)

      expect(obj.name).to eq("Test")
      expect(obj.category).to eq(EnumTest5::Category::B)

      serialized = Skit.serialize(obj)

      expect(serialized).to eq(data_with_category)
    end
  end

  describe "multiple enum properties" do
    let(:schema) do
      {
        "type" => "object",
        "title" => "Order",
        "properties" => {
          "id" => { "type" => "integer" },
          "status" => {
            "type" => "string",
            "enum" => %w[pending shipped delivered]
          },
          "priority" => {
            "type" => "string",
            "enum" => %w[low medium high]
          }
        },
        "required" => %w[id status priority]
      }
    end

    it "generates multiple T::Enum classes" do
      code = Skit::JsonSchema.generate(schema, module_name: "EnumTest6")

      expect(code).to include("class Status < T::Enum")
      expect(code).to include("class Priority < T::Enum")

      eval(code)

      order_data = {
        "id" => 123,
        "status" => "shipped",
        "priority" => "high"
      }

      order = Skit.deserialize(order_data, EnumTest6::Order)

      expect(order.id).to eq(123)
      expect(order.status).to eq(EnumTest6::Status::Shipped)
      expect(order.priority).to eq(EnumTest6::Priority::High)

      serialized = Skit.serialize(order)

      expect(serialized).to eq(order_data)
    end
  end
end
# rubocop:enable RSpec/DescribeClass, Security/Eval
