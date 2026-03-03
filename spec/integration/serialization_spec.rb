# typed: false
# frozen_string_literal: true

# rubocop:disable RSpec/DescribeClass, Lint/ConstantDefinitionInBlock
# rubocop:disable RSpec/BeforeAfterAll, RSpec/LeakyConstantDeclaration
require "spec_helper"

RSpec.describe "Complex object serialization", type: :integration do
  describe "nested structs" do
    before(:all) do
      module NestedStructTest
        class Address < T::Struct
          prop :city, String
          prop :zip, T.nilable(String)
        end

        class User < T::Struct
          prop :name, String
          prop :address, Address
        end
      end
    end

    it "deserializes nested hash to nested struct" do
      data = {
        "name" => "Alice",
        "address" => {
          "city" => "Tokyo",
          "zip" => "100-0001"
        }
      }

      result = Skit.deserialize(data, NestedStructTest::User)

      expect(result).to be_a(NestedStructTest::User)
      expect(result.name).to eq("Alice")
      expect(result.address).to be_a(NestedStructTest::Address)
      expect(result.address.city).to eq("Tokyo")
      expect(result.address.zip).to eq("100-0001")
    end

    it "serializes nested struct to hash" do
      user = NestedStructTest::User.new(
        name: "Bob",
        address: NestedStructTest::Address.new(
          city: "Osaka",
          zip: nil
        )
      )

      result = Skit.serialize(user)

      expect(result).to eq({
                             "name" => "Bob",
                             "address" => {
                               "city" => "Osaka",
                               "zip" => nil
                             }
                           })
    end

    it "round-trips nested data" do
      original = {
        "name" => "Charlie",
        "address" => {
          "city" => "Nagoya",
          "zip" => "450-0002"
        }
      }

      deserialized = Skit.deserialize(original, NestedStructTest::User)
      serialized = Skit.serialize(deserialized)

      expect(serialized).to eq(original)
    end
  end

  describe "const types" do
    before(:all) do
      module ConstTypeTest
        class TypeDog < Skit::JsonSchema::Types::Const
          VALUE = "dog"
        end

        class StatusVal200 < Skit::JsonSchema::Types::Const
          VALUE = 200
        end

        class EnabledTrue < Skit::JsonSchema::Types::Const
          VALUE = true
        end

        class Dog < T::Struct
          prop :type, TypeDog
          prop :name, String
        end

        class Response < T::Struct
          prop :status, StatusVal200
          prop :message, String
        end

        class Feature < T::Struct
          prop :enabled, EnabledTrue
          prop :name, String
        end
      end
    end

    it "deserializes string const" do
      data = { "type" => "dog", "name" => "Pochi" }

      result = Skit.deserialize(data, ConstTypeTest::Dog)

      expect(result.type).to be_a(ConstTypeTest::TypeDog)
      expect(result.type.value).to eq("dog")
      expect(result.name).to eq("Pochi")
    end

    it "serializes string const" do
      dog = ConstTypeTest::Dog.new(
        type: ConstTypeTest::TypeDog.new,
        name: "Shiro"
      )

      result = Skit.serialize(dog)

      expect(result).to eq({ "type" => "dog", "name" => "Shiro" })
    end

    it "deserializes integer const" do
      data = { "status" => 200, "message" => "OK" }

      result = Skit.deserialize(data, ConstTypeTest::Response)

      expect(result.status.value).to eq(200)
    end

    it "deserializes boolean const" do
      data = { "enabled" => true, "name" => "Dark Mode" }

      result = Skit.deserialize(data, ConstTypeTest::Feature)

      expect(result.enabled.value).to be(true)
    end

    it "raises error when const value does not match" do
      data = { "type" => "cat", "name" => "Tama" }

      expect do
        Skit.deserialize(data, ConstTypeTest::Dog)
      end.to raise_error(Skit::Serialization::DeserializeError, /Expected "dog", got "cat"/)
    end
  end

  describe "enum types" do
    before(:all) do
      module EnumTypeTest
        class Status < T::Enum
          enums do
            Pending = new("pending")
            InProgress = new("in_progress")
            Completed = new("completed")
          end
        end

        class Priority < T::Enum
          enums do
            Val1 = new(1)
            Val2 = new(2)
            Val3 = new(3)
          end
        end

        class Task < T::Struct
          prop :title, String
          prop :status, Status
          prop :priority, T.nilable(Priority)
        end
      end
    end

    it "deserializes string enum" do
      data = { "title" => "Test", "status" => "in_progress", "priority" => nil }

      result = Skit.deserialize(data, EnumTypeTest::Task)

      expect(result.status).to eq(EnumTypeTest::Status::InProgress)
    end

    it "deserializes integer enum" do
      data = { "title" => "Test", "status" => "pending", "priority" => 3 }

      result = Skit.deserialize(data, EnumTypeTest::Task)

      expect(result.priority).to eq(EnumTypeTest::Priority::Val3)
    end

    it "serializes enum values" do
      task = EnumTypeTest::Task.new(
        title: "Write docs",
        status: EnumTypeTest::Status::Completed,
        priority: EnumTypeTest::Priority::Val2
      )

      result = Skit.serialize(task)

      expect(result).to eq({
                             "title" => "Write docs",
                             "status" => "completed",
                             "priority" => 2
                           })
    end

    it "raises error for invalid enum value" do
      data = { "title" => "Test", "status" => "unknown", "priority" => nil }

      expect do
        Skit.deserialize(data, EnumTypeTest::Task)
      end.to raise_error(Skit::Serialization::DeserializeError, /Invalid value "unknown"/)
    end
  end

  describe "discriminated unions" do
    before(:all) do
      module DiscriminatedUnionTest
        class TypeDog < Skit::JsonSchema::Types::Const
          VALUE = "dog"
        end

        class TypeCat < Skit::JsonSchema::Types::Const
          VALUE = "cat"
        end

        class Dog < T::Struct
          prop :type, TypeDog
          prop :name, String
          prop :breed, String
        end

        class Cat < T::Struct
          prop :type, TypeCat
          prop :name, String
          prop :color, String
        end

        class Container < T::Struct
          prop :id, Integer
          prop :animal, T.any(Dog, Cat)
        end
      end
    end

    it "deserializes to Dog when type is 'dog'" do
      data = {
        "id" => 1,
        "animal" => { "type" => "dog", "name" => "Pochi", "breed" => "Shiba" }
      }

      result = Skit.deserialize(data, DiscriminatedUnionTest::Container)

      expect(result.animal).to be_a(DiscriminatedUnionTest::Dog)
      expect(result.animal.type.value).to eq("dog")
      expect(result.animal.breed).to eq("Shiba")
    end

    it "deserializes to Cat when type is 'cat'" do
      data = {
        "id" => 2,
        "animal" => { "type" => "cat", "name" => "Tama", "color" => "white" }
      }

      result = Skit.deserialize(data, DiscriminatedUnionTest::Container)

      expect(result.animal).to be_a(DiscriminatedUnionTest::Cat)
      expect(result.animal.type.value).to eq("cat")
      expect(result.animal.color).to eq("white")
    end

    it "serializes Dog correctly" do
      container = DiscriminatedUnionTest::Container.new(
        id: 1,
        animal: DiscriminatedUnionTest::Dog.new(
          type: DiscriminatedUnionTest::TypeDog.new,
          name: "Max",
          breed: "Golden"
        )
      )

      result = Skit.serialize(container)

      expect(result).to eq({
                             "id" => 1,
                             "animal" => { "type" => "dog", "name" => "Max", "breed" => "Golden" }
                           })
    end

    it "raises error when no matching type found" do
      data = {
        "id" => 3,
        "animal" => { "type" => "bird", "name" => "Piyo" }
      }

      expect do
        Skit.deserialize(data, DiscriminatedUnionTest::Container)
      end.to raise_error(Skit::Serialization::DeserializeError, /No matching struct found/)
    end

    it "round-trips discriminated union data" do
      original = {
        "id" => 100,
        "animal" => { "type" => "cat", "name" => "Whiskers", "color" => "orange" }
      }

      deserialized = Skit.deserialize(original, DiscriminatedUnionTest::Container)
      serialized = Skit.serialize(deserialized)

      expect(serialized).to eq(original)
    end
  end

  describe "arrays of complex objects" do
    before(:all) do
      module ArrayComplexTest
        class Item < T::Struct
          prop :id, Integer
          prop :name, String
        end

        class Container < T::Struct
          prop :items, T::Array[Item]
        end
      end
    end

    it "deserializes array of structs" do
      data = {
        "items" => [
          { "id" => 1, "name" => "First" },
          { "id" => 2, "name" => "Second" }
        ]
      }

      result = Skit.deserialize(data, ArrayComplexTest::Container)

      expect(result.items.length).to eq(2)
      expect(result.items[0]).to be_a(ArrayComplexTest::Item)
      expect(result.items[0].name).to eq("First")
      expect(result.items[1].name).to eq("Second")
    end

    it "serializes array of structs" do
      container = ArrayComplexTest::Container.new(
        items: [
          ArrayComplexTest::Item.new(id: 10, name: "A"),
          ArrayComplexTest::Item.new(id: 20, name: "B")
        ]
      )

      result = Skit.serialize(container)

      expect(result).to eq({
                             "items" => [
                               { "id" => 10, "name" => "A" },
                               { "id" => 20, "name" => "B" }
                             ]
                           })
    end
  end

  describe "hash with complex values" do
    before(:all) do
      module HashComplexTest
        class Config < T::Struct
          prop :value, Integer
          prop :enabled, T::Boolean
        end

        class Container < T::Struct
          prop :configs, T::Hash[String, Config]
        end
      end
    end

    it "deserializes hash with struct values" do
      data = {
        "configs" => {
          "feature_a" => { "value" => 10, "enabled" => true },
          "feature_b" => { "value" => 20, "enabled" => false }
        }
      }

      result = Skit.deserialize(data, HashComplexTest::Container)

      expect(result.configs["feature_a"]).to be_a(HashComplexTest::Config)
      expect(result.configs["feature_a"].value).to eq(10)
      expect(result.configs["feature_b"].enabled).to be(false)
    end

    it "serializes hash with struct values" do
      container = HashComplexTest::Container.new(
        configs: {
          "x" => HashComplexTest::Config.new(value: 1, enabled: true)
        }
      )

      result = Skit.serialize(container)

      expect(result).to eq({
                             "configs" => {
                               "x" => { "value" => 1, "enabled" => true }
                             }
                           })
    end
  end

  describe "date and time types" do
    before(:all) do
      module DateTimeTest
        class Event < T::Struct
          prop :name, String
          prop :date, Date
          prop :starts_at, T.nilable(Time)
        end
      end
    end

    it "deserializes date and time strings" do
      data = {
        "name" => "Meeting",
        "date" => "2025-01-15",
        "starts_at" => "2025-01-15T10:30:00+09:00"
      }

      result = Skit.deserialize(data, DateTimeTest::Event)

      expect(result.date).to eq(Date.new(2025, 1, 15))
      expect(result.starts_at).to be_a(Time)
      expect(result.starts_at.hour).to eq(10)
    end

    it "serializes date and time to ISO8601" do
      event = DateTimeTest::Event.new(
        name: "Conference",
        date: Date.new(2025, 6, 20),
        starts_at: Time.new(2025, 6, 20, 9, 0, 0, "+09:00")
      )

      result = Skit.serialize(event)

      expect(result["date"]).to eq("2025-06-20")
      expect(result["starts_at"]).to match(/^2025-06-20T09:00:00/)
    end
  end
end
# rubocop:enable RSpec/DescribeClass, Lint/ConstantDefinitionInBlock
# rubocop:enable RSpec/BeforeAfterAll, RSpec/LeakyConstantDeclaration
