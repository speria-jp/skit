# typed: false
# frozen_string_literal: true

# rubocop:disable Lint/ConstantDefinitionInBlock, RSpec/LeakyConstantDeclaration
# rubocop:disable RSpec/DescribeClass, RSpec/BeforeAfterAll, Sorbet/BlockMethodDefinition
require "spec_helper"
require "active_record"
require_relative "../support/database_config"

RSpec.describe "Nested validation integration", type: :integration do
  class ValidatedAddress < T::Struct
    include ActiveModel::Validations

    const :city, String
    const :zip, T.nilable(String)

    validates :city, presence: true, length: { minimum: 2 }
    validates :zip, format: { with: /\A\d{3}-\d{4}\z/, message: "must be in format XXX-XXXX" },
                    allow_nil: true
  end

  class ValidatedProduct < T::Struct
    include ActiveModel::Validations

    const :name, String
    const :price, Integer

    validates :name, presence: true
    validates :price, numericality: { greater_than: 0 }
  end

  class ValidatedOrderItem < T::Struct
    include ActiveModel::Validations

    const :product, ValidatedProduct
    const :quantity, Integer

    validates :quantity, numericality: { greater_than: 0 }
  end

  before(:all) do
    ActiveRecord::Base.establish_connection(DatabaseConfig.connection_config("sqlite3"))
  end

  before do
    suppress_output do
      ActiveRecord::Schema.define do
        create_table :validated_customers, force: true do |t|
          t.json :address
          t.timestamps
        end

        create_table :validated_orders, force: true do |t|
          t.json :items
          t.timestamps
        end

        create_table :validated_stores, force: true do |t|
          t.json :products
          t.timestamps
        end
      end
    end

    define_validated_customer_model
    define_validated_order_model
    define_validated_store_model
  end

  after do
    # rubocop:disable RSpec/RemoveConst
    Object.send(:remove_const, :ValidatedCustomer) if defined?(ValidatedCustomer)
    Object.send(:remove_const, :ValidatedOrder) if defined?(ValidatedOrder)
    Object.send(:remove_const, :ValidatedStore) if defined?(ValidatedStore)
    # rubocop:enable RSpec/RemoveConst
  end

  describe "single struct validation" do
    it "validates nested struct and adds errors to parent" do
      customer = ValidatedCustomer.new(address: { city: "", zip: "invalid" })

      expect(customer).not_to be_valid
      expect(customer.errors[:"address.city"]).to include(/blank/)
      expect(customer.errors[:"address.zip"]).to include(/format/)
    end

    it "passes validation with valid data" do
      customer = ValidatedCustomer.new(address: { city: "Tokyo", zip: "100-0001" })

      expect(customer).to be_valid
    end

    it "passes validation with nil value" do
      customer = ValidatedCustomer.new(address: nil)

      expect(customer).to be_valid
    end

    it "validates minimum length" do
      customer = ValidatedCustomer.new(address: { city: "X" })

      expect(customer).not_to be_valid
      expect(customer.errors[:"address.city"]).to include(/short/)
    end
  end

  describe "array of structs validation" do
    it "validates each item in array with indexed errors" do
      products = [
        { name: "Valid", price: 100 },
        { name: "", price: 0 },
        { name: "Another", price: -10 }
      ]
      store = ValidatedStore.new(products: products)

      expect(store).not_to be_valid
      expect(store.errors[:"products.[1].name"]).to include(/blank/)
      expect(store.errors[:"products.[1].price"]).to include(/greater than 0/)
      expect(store.errors[:"products.[2].price"]).to include(/greater than 0/)
    end

    it "passes validation with all valid items" do
      products = [
        { name: "Book", price: 1500 },
        { name: "Pen", price: 200 }
      ]
      store = ValidatedStore.new(products: products)

      expect(store).to be_valid
    end

    it "passes validation with empty array" do
      store = ValidatedStore.new(products: [])

      expect(store).to be_valid
    end
  end

  describe "deeply nested validation" do
    it "validates nested structs within array items" do
      items = [
        {
          product: { name: "Laptop", price: 150_000 },
          quantity: 1
        },
        {
          product: { name: "", price: 0 },
          quantity: -1
        }
      ]
      order = ValidatedOrder.new(items: items)

      expect(order).not_to be_valid
      expect(order.errors[:"items.[1].product.name"]).to include(/blank/)
      expect(order.errors[:"items.[1].product.price"]).to include(/greater than 0/)
      expect(order.errors[:"items.[1].quantity"]).to include(/greater than 0/)
    end

    it "passes validation with valid nested data" do
      items = [
        {
          product: { name: "Mouse", price: 3000 },
          quantity: 2
        }
      ]
      order = ValidatedOrder.new(items: items)

      expect(order).to be_valid
    end
  end

  describe "save with validation" do
    it "prevents saving invalid records" do
      customer = ValidatedCustomer.new(address: { city: "" })

      expect(customer.save).to be(false)
      expect(customer.errors[:"address.city"]).not_to be_empty
    end

    it "saves valid records" do
      customer = ValidatedCustomer.new(address: { city: "Tokyo", zip: "100-0001" })

      expect(customer.save).to be(true)
      expect(customer.id).not_to be_nil
    end

    it "raises error on save! with invalid record" do
      customer = ValidatedCustomer.new(address: { city: "" })

      expect { customer.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  def define_validated_customer_model
    Object.const_set(:ValidatedCustomer, Class.new(ActiveRecord::Base) do
      self.table_name = "validated_customers"
      attribute :address, Skit::Attribute[ValidatedAddress]
      validates :address, skit: true
    end)
  end

  def define_validated_order_model
    Object.const_set(:ValidatedOrder, Class.new(ActiveRecord::Base) do
      self.table_name = "validated_orders"
      attribute :items, Skit::Attribute[T::Array[ValidatedOrderItem]]
      validates :items, skit: true
    end)
  end

  def define_validated_store_model
    Object.const_set(:ValidatedStore, Class.new(ActiveRecord::Base) do
      self.table_name = "validated_stores"
      attribute :products, Skit::Attribute[T::Array[ValidatedProduct]]
      validates :products, skit: true
    end)
  end

  def suppress_output
    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    yield
  ensure
    $stdout = original_stdout
    $stderr = original_stderr
  end
end
# rubocop:enable Lint/ConstantDefinitionInBlock, RSpec/LeakyConstantDeclaration
# rubocop:enable RSpec/DescribeClass, RSpec/BeforeAfterAll, Sorbet/BlockMethodDefinition
