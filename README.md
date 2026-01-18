# Skit

A Ruby gem that integrates JSON Schema with Sorbet T::Struct. Generate type-safe Ruby code from JSON Schema, serialize/deserialize JSON data to T::Struct, and store complex objects in ActiveRecord JSON/JSONB columns.

## Key Features

- **JSON Schema to Code**: Generate Sorbet T::Struct definitions from JSON Schema
- **Type-Safe Serialization**: Seamless conversion between T::Struct and JSON
- **ActiveRecord Integration**: Store T::Struct in JSON/JSONB columns with full type safety
- **Validation**: Automatic validation with indexed error messages for nested structures
- **Database Agnostic**: PostgreSQL, MySQL, and SQLite support

## Installation

Add this line to your application's Gemfile:

```ruby
gem "skit"
```

And then execute:

```bash
bundle install
```

## Usage

### 1. Generate T::Struct from JSON Schema

#### CLI Tool

```bash
# Basic usage
skit generate schema.json

# Specify class name
skit generate -c User user_schema.json

# Specify module name
skit generate -m MyModule user_schema.json

# Output to file
skit generate -o lib/types/user.rb user_schema.json

# Combine options
skit generate -m MyApp::Types -c User -o user.rb user_schema.json
```

#### Programmatic API

```ruby
require "skit"

schema = {
  "type" => "object",
  "properties" => {
    "name" => { "type" => "string" },
    "age" => { "type" => "integer" }
  },
  "required" => ["name"]
}

code = Skit::JsonSchema.generate(schema, class_name: "User", module_name: "MyApp")
puts code
```

Output:

```ruby
# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

module MyApp
  class User < T::Struct
    prop :name, String
    prop :age, T.nilable(Integer)
  end
end
```

#### Enum Support

JSON Schema `enum` generates `T::Enum` classes:

```json
{
  "type": "object",
  "properties": {
    "status": {
      "type": "string",
      "enum": ["pending", "active", "completed"]
    }
  }
}
```

Generates:

```ruby
class Status < T::Enum
  enums do
    Pending = new("pending")
    Active = new("active")
    Completed = new("completed")
  end
end

class Root < T::Struct
  prop :status, T.nilable(Status)
end
```

#### Const Support

JSON Schema `const` generates type-safe constant classes for discriminated unions:

```json
{
  "type": "object",
  "properties": {
    "type": { "const": "dog" },
    "breed": { "type": "string" }
  }
}
```

Generates:

```ruby
class TypeDog < Skit::JsonSchema::Types::Const
  VALUE = "dog"
end

class Root < T::Struct
  prop :type, T.nilable(TypeDog)
  prop :breed, T.nilable(String)
end
```

#### Discriminated Unions (oneOf with objects)

JSON Schema `oneOf` with object types generates union types:

```json
{
  "properties": {
    "animal": {
      "oneOf": [
        { "type": "object", "properties": { "type": { "const": "dog" }, "breed": { "type": "string" } } },
        { "type": "object", "properties": { "type": { "const": "cat" }, "color": { "type": "string" } } }
      ]
    }
  }
}
```

Generates:

```ruby
class AnimalVariant0 < T::Struct
  prop :type, T.nilable(TypeDog)
  prop :breed, T.nilable(String)
end

class AnimalVariant1 < T::Struct
  prop :type, T.nilable(TypeCat)
  prop :color, T.nilable(String)
end

class Root < T::Struct
  prop :animal, T.any(AnimalVariant0, AnimalVariant1)
end
```

### 2. Serialize/Deserialize T::Struct

Use your own T::Struct definitions directly:

```ruby
class Product < T::Struct
  const :name, String
  const :price, Integer
  const :tags, T::Array[String], default: []
end

# Deserialize: Hash -> T::Struct
data = { "name" => "Ruby Book", "price" => 3000, "tags" => ["programming", "ruby"] }
product = Skit.deserialize(data, Product)

product.name  # => "Ruby Book"
product.price # => 3000
product.tags  # => ["programming", "ruby"]

# Serialize: T::Struct -> Hash
hash = Skit.serialize(product)
# => {"name" => "Ruby Book", "price" => 3000, "tags" => ["programming", "ruby"]}
```

### 3. ActiveRecord JSONB Integration

```ruby
class Address < T::Struct
  const :city, String
  const :zip, T.nilable(String)
end

class Customer < ActiveRecord::Base
  attribute :address, Skit::Attribute[Address]
end

# Assign with Hash
customer = Customer.new
customer.address = { city: "Tokyo", zip: "100-0001" }

# Assign with T::Struct
customer.address = Address.new(city: "Tokyo", zip: "100-0001")

# Access as T::Struct
customer.address.city  # => "Tokyo"
customer.address.zip   # => "100-0001"

# Save to database (stored as json)
customer.save
```

### Array Type

```ruby
class Tag < T::Struct
  const :name, String
  const :color, String
end

class Article < ActiveRecord::Base
  attribute :tags, Skit::Attribute[T::Array[Tag]]
end

article = Article.new
article.tags = [
  { name: "Ruby", color: "red" },
  { name: "Rails", color: "red" }
]

article.tags[0].name  # => "Ruby"
```

### Hash Type

```ruby
class BoxSize < T::Struct
  const :width, Integer
  const :height, Integer
end

class Layout < ActiveRecord::Base
  attribute :sizes, Skit::Attribute[T::Hash[String, BoxSize]]
end

layout = Layout.new
layout.sizes = {
  "small" => { width: 100, height: 50 },
  "large" => { width: 200, height: 100 }
}

layout.sizes["small"].width  # => 100
```

### Nested Structs

```ruby
class Address < T::Struct
  const :street, String
  const :city, String
end

class Company < T::Struct
  const :name, String
  const :address, Address
end

class Employee < ActiveRecord::Base
  attribute :company, Skit::Attribute[Company]
end

employee = Employee.new
employee.company = {
  name: "Acme Corp",
  address: { street: "123 Main St", city: "Springfield" }
}

employee.company.address.city  # => "Springfield"
```

### Validation

Skit integrates with ActiveModel::Validations:

```ruby
class Product < T::Struct
  include ActiveModel::Validations

  const :name, String
  const :price, Integer

  validates :name, presence: true
  validates :price, numericality: { greater_than: 0 }
end

class Order < ActiveRecord::Base
  attribute :product, Skit::Attribute[Product]
  validates :product, skit: true
end

order = Order.new
order.product = { name: "", price: -100 }
order.valid?  # => false
order.errors[:"product.name"]   # => ["can't be blank"]
order.errors[:"product.price"]  # => ["must be greater than 0"]
```

Array elements are validated with indexed error keys:

```ruby
class Item < T::Struct
  include ActiveModel::Validations

  const :name, String
  validates :name, presence: true
end

class Cart < ActiveRecord::Base
  attribute :items, Skit::Attribute[T::Array[Item]]
  validates :items, skit: true
end

cart = Cart.new
cart.items = [{ name: "Book" }, { name: "" }]
cart.valid?  # => false
cart.errors[:"items.[1].name"]  # => ["can't be blank"]
```

## Type Mapping

### JSON Schema to Sorbet

| JSON Schema | Sorbet Type |
|-------------|-------------|
| `string` | `String` |
| `string` (format: date) | `Date` |
| `string` (format: date-time) | `DateTime` |
| `string` (format: time) | `Time` |
| `integer` | `Integer` |
| `number` | `Float` |
| `boolean` | `T::Boolean` |
| `array` | `T::Array[ElementType]` |
| `object` (with properties) | Custom T::Struct |
| `object` (no properties) | `T::Hash[String, T.untyped]` |
| `anyOf`/`oneOf` | `T.any(...)` or `T.nilable(...)` |
| `anyOf`/`oneOf` (objects) | `T.any(Struct1, Struct2, ...)` |
| `enum` | `T::Enum` |
| `const` | `Skit::JsonSchema::Types::Const` subclass |

### Sorbet to JSON (Serialization)

| Sorbet Type | JSON Type |
|-------------|-----------|
| `String` | `string` |
| `Integer`, `Float` | `number` |
| `T::Boolean` | `boolean` |
| `Symbol` | `string` |
| `Date` | `string` (ISO 8601: `"2025-01-15"`) |
| `Time` | `string` (ISO 8601: `"2025-01-15T10:30:00+09:00"`) |
| `T::Struct` | `object` |
| `T::Array[T]` | `array` |
| `T::Hash[String, T]` | `object` |
| `T.nilable(T)` | type or `null` |

## CLI Reference

```bash
skit generate [OPTIONS] SCHEMA_FILE

Options:
  -c, --class-name NAME    Root class name (default: from schema title or "GeneratedClass")
  -m, --module-name NAME   Module name to wrap generated classes
  -o, --output FILE        Output file path (default: stdout)
  --typed LEVEL            Sorbet strictness level (default: "strict")
  -h, --help               Show help message
  -v, --version            Show version
```

## Development

After checking out the repo, run `bundle install` to install dependencies.

### Running Tests

```bash
# Run all tests and linters (default task)
bundle exec rake

# Run tests only
bundle exec rspec

# Run unit tests only
bundle exec rspec --tag type:unit

# Run integration tests only
bundle exec rspec --tag type:integration
```

### Code Quality

```bash
# Run RuboCop (linter)
bundle exec rubocop
bundle exec rubocop -a  # Auto-fix

# Run Sorbet type checker
bundle exec srb tc

# Update RBI files (Tapioca)
bundle exec rake sorbet:update
```

## License

MIT License. See LICENSE file for details.
