# typed: false
# frozen_string_literal: true

# rubocop:disable Lint/ConstantDefinitionInBlock, RSpec/LeakyConstantDeclaration
# rubocop:disable RSpec/DescribeClass, RSpec/BeforeAfterAll, Sorbet/BlockMethodDefinition
require "spec_helper"
require "active_record"
require_relative "../support/database_config"

RSpec.describe "ActiveRecord JSONB integration", type: :integration do
  ADAPTERS = %w[sqlite3].freeze

  class Address < T::Struct
    const :city, String
    const :zip, T.nilable(String)
    const :country, String, default: "Japan"
  end

  class Product < T::Struct
    const :name, String
    const :price, Integer
    const :tags, T::Array[String], default: []
  end

  class OrderItem < T::Struct
    const :product, Product
    const :quantity, Integer
  end

  ADAPTERS.each do |adapter|
    context "with #{adapter}" do
      let(:column_type) { DatabaseConfig.column_type(adapter) }

      before(:all) do
        ActiveRecord::Base.establish_connection(DatabaseConfig.connection_config(adapter))
      end

      before do
        suppress_output do
          ActiveRecord::Schema.define do
            create_table :customers, force: true do |t|
              t.json :address
              t.timestamps
            end

            create_table :shops, force: true do |t|
              t.json :products
              t.timestamps
            end

            create_table :orders, force: true do |t|
              t.json :items
              t.timestamps
            end
          end
        end

        define_customer_model
        define_shop_model
        define_order_model
      end

      after do
        # rubocop:disable RSpec/RemoveConst
        Object.send(:remove_const, :Customer) if defined?(Customer)
        Object.send(:remove_const, :Shop) if defined?(Shop)
        Object.send(:remove_const, :Order) if defined?(Order)
        # rubocop:enable RSpec/RemoveConst
      end

      describe "single T::Struct attribute" do
        it "saves and loads a struct" do
          customer = Customer.create!(address: { city: "Tokyo", zip: "100-0001" })

          customer.reload
          expect(customer.address).to be_a(Address)
          expect(customer.address.city).to eq("Tokyo")
          expect(customer.address.zip).to eq("100-0001")
          expect(customer.address.country).to eq("Japan")
        end

        it "accepts T::Struct instance" do
          addr = Address.new(city: "Osaka", zip: "530-0001")
          customer = Customer.create!(address: addr)

          customer.reload
          expect(customer.address.city).to eq("Osaka")
        end

        it "handles nil value" do
          customer = Customer.create!(address: nil)

          customer.reload
          expect(customer.address).to be_nil
        end

        it "handles default values" do
          customer = Customer.create!(address: { city: "Kyoto" })

          customer.reload
          expect(customer.address.country).to eq("Japan")
          expect(customer.address.zip).to be_nil
        end
      end

      describe "T::Array attribute" do
        it "saves and loads an array of structs" do
          products = [
            { name: "Book", price: 1500 },
            { name: "Pen", price: 200 }
          ]
          shop = Shop.create!(products: products)

          shop.reload
          expect(shop.products.size).to eq(2)
          expect(shop.products[0]).to be_a(Product)
          expect(shop.products[0].name).to eq("Book")
          expect(shop.products[0].price).to eq(1500)
          expect(shop.products[1].name).to eq("Pen")
        end

        it "handles empty array" do
          shop = Shop.create!(products: [])

          shop.reload
          expect(shop.products).to eq([])
        end

        it "handles nil array" do
          shop = Shop.create!(products: nil)

          shop.reload
          expect(shop.products).to be_nil
        end
      end

      describe "nested T::Struct attribute" do
        it "saves and loads nested structs" do
          items = [
            {
              product: { name: "Laptop", price: 150_000, tags: ["electronics"] },
              quantity: 1
            },
            {
              product: { name: "Mouse", price: 3000 },
              quantity: 2
            }
          ]
          order = Order.create!(items: items)

          order.reload
          expect(order.items.size).to eq(2)
          expect(order.items[0]).to be_a(OrderItem)
          expect(order.items[0].product).to be_a(Product)
          expect(order.items[0].product.name).to eq("Laptop")
          expect(order.items[0].product.price).to eq(150_000)
          expect(order.items[0].product.tags).to eq(["electronics"])
          expect(order.items[0].quantity).to eq(1)
          expect(order.items[1].product.name).to eq("Mouse")
          expect(order.items[1].product.tags).to eq([])
        end
      end

      describe "update operations" do
        it "updates struct attribute" do
          customer = Customer.create!(address: { city: "Tokyo" })
          customer.update!(address: { city: "Osaka", zip: "530-0001" })

          customer.reload
          expect(customer.address.city).to eq("Osaka")
          expect(customer.address.zip).to eq("530-0001")
        end

        it "detects changes in struct attribute" do
          customer = Customer.create!(address: { city: "Tokyo" })

          customer.address = { city: "Osaka" }
          expect(customer.address_changed?).to be(true)

          customer.save!
          customer.reload
          expect(customer.address.city).to eq("Osaka")
        end
      end

      describe "query operations" do
        it "finds records by id" do
          customer = Customer.create!(address: { city: "Tokyo" })
          found = Customer.find(customer.id)

          expect(found.address.city).to eq("Tokyo")
        end
      end

      def define_customer_model
        Object.const_set(:Customer, Class.new(ActiveRecord::Base) do
          self.table_name = "customers"
          attribute :address, Skit::Attribute[Address]
        end)
      end

      def define_shop_model
        Object.const_set(:Shop, Class.new(ActiveRecord::Base) do
          self.table_name = "shops"
          attribute :products, Skit::Attribute[T::Array[Product]]
        end)
      end

      def define_order_model
        Object.const_set(:Order, Class.new(ActiveRecord::Base) do
          self.table_name = "orders"
          attribute :items, Skit::Attribute[T::Array[OrderItem]]
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
  end
end
# rubocop:enable Lint/ConstantDefinitionInBlock, RSpec/LeakyConstantDeclaration
# rubocop:enable RSpec/DescribeClass, RSpec/BeforeAfterAll, Sorbet/BlockMethodDefinition
