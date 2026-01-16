# typed: false
# frozen_string_literal: true

require "spec_helper"
require "active_record"

begin
  require "tapioca"
  require "tapioca/dsl"
rescue LoadError
  # Skip if tapioca is not available
end

return unless defined?(Tapioca::Dsl::Compiler)

require "tapioca/dsl/compilers/skit"

RSpec.describe Tapioca::Dsl::Compilers::Skit, type: :tapioca_integration do
  after do
    ActiveRecord::Base.connection.tables.each do |table|
      next if %w[schema_migrations ar_internal_metadata].include?(table)

      ActiveRecord::Base.connection.drop_table(table, if_exists: true)
    end
  end

  describe ".gather_constants" do
    context "with Skit::Attribute attributes" do
      before do
        ActiveRecord::Schema.define do
          create_table :inventory_items, force: true do |t|
            t.json :metadata
            t.json :tags
          end
        end

        add_ruby_file("inventory_item_metadata.rb", <<~RUBY)
          class InventoryItemMetadata < T::Struct
            const :manufacturer, String
            const :weight_kg, Integer
          end

          class InventoryItemTag < T::Struct
            const :label, String
            const :value, String
          end

          class InventoryItem < ActiveRecord::Base
            attribute :metadata, Skit::Attribute[InventoryItemMetadata]
            attribute :tags, Skit::Attribute[T::Array[InventoryItemTag]]
          end
        RUBY
      end

      it "includes ActiveRecord models with Skit::Attribute attributes" do
        constants = described_class.gather_constants
        expect(constants).to include(InventoryItem)
      end
    end

    context "without Skit::Attribute attributes" do
      before do
        ActiveRecord::Schema.define do
          create_table :regular_models, force: true do |t|
            t.string :name
          end
        end

        add_ruby_file("regular_model.rb", <<~RUBY)
          class RegularModel < ActiveRecord::Base
          end
        RUBY
      end

      it "excludes ActiveRecord models without Skit::Attribute attributes" do
        constants = described_class.gather_constants
        expect(constants).not_to include(RegularModel)
        expect(constants).not_to include(InventoryItem) if defined?(InventoryItem)
      end
    end
  end

  describe "#decorate" do
    context "with single Skit::Attribute attribute" do
      before do
        ActiveRecord::Schema.define do
          create_table :shops, force: true do |t|
            t.json :info
          end
        end

        add_ruby_file("shop_info.rb", <<~RUBY)
          class ShopInfo < T::Struct
            const :name, String
            const :address, String
          end

          class Shop < ActiveRecord::Base
            attribute :info, Skit::Attribute[ShopInfo]
          end
        RUBY
      end

      it "generates RBI for single Skit::Attribute attribute" do
        rbi_output = rbi_for(Shop)

        expected_rbi = <<~RBI
          # typed: strong

          class Shop
            sig { returns(ShopInfo) }
            def info; end

            sig { params(value: T.untyped).returns(ShopInfo) }
            def info=(value); end
          end
        RBI

        expect(rbi_output.strip).to eq(expected_rbi.strip)
      end
    end

    context "with array Skit::Attribute attribute" do
      before do
        ActiveRecord::Schema.define do
          create_table :warehouses, force: true do |t|
            t.json :items
          end
        end

        add_ruby_file("item.rb", <<~RUBY)
          class Item < T::Struct
            const :sku, String
            const :quantity, Integer
          end

          class Warehouse < ActiveRecord::Base
            attribute :items, Skit::Attribute[T::Array[Item]]
          end
        RUBY
      end

      it "generates RBI for array Skit::Attribute attribute" do
        rbi_output = rbi_for(Warehouse)

        expected_rbi = <<~RBI
          # typed: strong

          class Warehouse
            sig { returns(T::Array[Item]) }
            def items; end

            sig { params(value: T.untyped).returns(T::Array[Item]) }
            def items=(value); end
          end
        RBI

        expect(rbi_output.strip).to eq(expected_rbi.strip)
      end
    end

    context "with hash Skit::Attribute attribute" do
      before do
        ActiveRecord::Schema.define do
          create_table :catalogs, force: true do |t|
            t.json :products
          end
        end

        add_ruby_file("catalog_product.rb", <<~RUBY)
          class CatalogProduct < T::Struct
            const :name, String
            const :price, Integer
          end

          class Catalog < ActiveRecord::Base
            attribute :products, Skit::Attribute[T::Hash[String, CatalogProduct]]
          end
        RUBY
      end

      it "generates RBI for hash Skit::Attribute attribute" do
        rbi_output = rbi_for(Catalog)

        expected_rbi = <<~RBI
          # typed: strong

          class Catalog
            sig { returns(T::Hash[String, CatalogProduct]) }
            def products; end

            sig { params(value: T.untyped).returns(T::Hash[String, CatalogProduct]) }
            def products=(value); end
          end
        RBI

        expect(rbi_output.strip).to eq(expected_rbi.strip)
      end
    end

    context "with both single and array attributes" do
      before do
        ActiveRecord::Schema.define do
          create_table :stores, force: true do |t|
            t.json :config
            t.json :products
          end
        end

        add_ruby_file("store_config.rb", <<~RUBY)
          class StoreConfig < T::Struct
            const :theme, String
          end

          class StoreProduct < T::Struct
            const :name, String
          end

          class Store < ActiveRecord::Base
            attribute :config, Skit::Attribute[StoreConfig]
            attribute :products, Skit::Attribute[T::Array[StoreProduct]]
          end
        RUBY
      end

      it "generates RBI for both attribute types" do
        rbi_output = rbi_for(Store)

        expected_rbi = <<~RBI
          # typed: strong

          class Store
            sig { returns(StoreConfig) }
            def config; end

            sig { params(value: T.untyped).returns(StoreConfig) }
            def config=(value); end

            sig { returns(T::Array[StoreProduct]) }
            def products; end

            sig { params(value: T.untyped).returns(T::Array[StoreProduct]) }
            def products=(value); end
          end
        RBI

        expect(rbi_output.strip).to eq(expected_rbi.strip)
      end
    end

    context "with all three attribute types" do
      before do
        ActiveRecord::Schema.define do
          create_table :inventory_systems, force: true do |t|
            t.json :settings
            t.json :items
            t.json :locations
          end
        end

        add_ruby_file("inventory_system.rb", <<~RUBY)
          class SystemSettings < T::Struct
            const :version, String
          end

          class InventorySystemItem < T::Struct
            const :sku, String
          end

          class Location < T::Struct
            const :name, String
          end

          class InventorySystem < ActiveRecord::Base
            attribute :settings, Skit::Attribute[SystemSettings]
            attribute :items, Skit::Attribute[T::Array[InventorySystemItem]]
            attribute :locations, Skit::Attribute[T::Hash[String, Location]]
          end
        RUBY
      end

      it "generates RBI for all three attribute types" do
        rbi_output = rbi_for(InventorySystem)

        expected_rbi = <<~RBI
          # typed: strong

          class InventorySystem
            sig { returns(SystemSettings) }
            def settings; end

            sig { params(value: T.untyped).returns(SystemSettings) }
            def settings=(value); end

            sig { returns(T::Array[InventorySystemItem]) }
            def items; end

            sig { params(value: T.untyped).returns(T::Array[InventorySystemItem]) }
            def items=(value); end

            sig { returns(T::Hash[String, Location]) }
            def locations; end

            sig { params(value: T.untyped).returns(T::Hash[String, Location]) }
            def locations=(value); end
          end
        RBI

        expect(rbi_output.strip).to eq(expected_rbi.strip)
      end
    end

    context "with union type attribute (T.any)" do
      before do
        ActiveRecord::Schema.define do
          create_table :pet_owners, force: true do |t|
            t.json :pet
          end
        end

        add_ruby_file("pet_owner.rb", <<~RUBY)
          class PetOwnerPetType < T::Enum
            enums do
              Dog = new("dog")
              Cat = new("cat")
            end
          end

          class PetOwnerDog < T::Struct
            const :type, PetOwnerPetType::Dog
            const :breed, String
          end

          class PetOwnerCat < T::Struct
            const :type, PetOwnerPetType::Cat
            const :color, String
          end

          class PetOwner < ActiveRecord::Base
            attribute :pet, Skit::Attribute[T.any(PetOwnerDog, PetOwnerCat)]
          end
        RUBY
      end

      it "generates RBI for union type attribute" do
        rbi_output = rbi_for(PetOwner)

        # NOTE: Sorbet may reorder types alphabetically, so we check for either order
        expected_rbi = <<~RBI
          # typed: strong

          class PetOwner
            sig { returns(T.any(PetOwnerCat, PetOwnerDog)) }
            def pet; end

            sig { params(value: T.untyped).returns(T.any(PetOwnerCat, PetOwnerDog)) }
            def pet=(value); end
          end
        RBI

        expect(rbi_output.strip).to eq(expected_rbi.strip)
      end
    end

    context "with T::Enum value type attribute" do
      before do
        ActiveRecord::Schema.define do
          create_table :animal_records, force: true do |t|
            t.json :animal
          end
        end

        add_ruby_file("animal_record.rb", <<~RUBY)
          class AnimalRecordType < T::Enum
            enums do
              Dog = new("dog")
              Cat = new("cat")
            end
          end

          class AnimalRecordDog < T::Struct
            const :type, AnimalRecordType::Dog
            const :breed, String
          end

          class AnimalRecord < ActiveRecord::Base
            attribute :animal, Skit::Attribute[AnimalRecordDog]
          end
        RUBY
      end

      it "generates RBI for struct with T::Enum value type" do
        rbi_output = rbi_for(AnimalRecord)

        expected_rbi = <<~RBI
          # typed: strong

          class AnimalRecord
            sig { returns(AnimalRecordDog) }
            def animal; end

            sig { params(value: T.untyped).returns(AnimalRecordDog) }
            def animal=(value); end
          end
        RBI

        expect(rbi_output.strip).to eq(expected_rbi.strip)
      end
    end
  end
end
