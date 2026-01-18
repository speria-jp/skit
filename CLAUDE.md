# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Skit is a Ruby gem that integrates JSON Schema with Sorbet T::Struct. It provides:

- **JSON Schema to Code**: Generate Sorbet T::Struct definitions from JSON Schema
- **Type-Safe Serialization**: Seamless conversion between T::Struct and JSON
- **ActiveRecord Integration**: Store T::Struct in JSON/JSONB columns with full type safety
- **Validation**: Automatic validation with indexed error messages for nested structures

Supports PostgreSQL, MySQL, and SQLite.

## Commands

### Testing and Quality Checks

```bash
# Default task (runs RuboCop + RSpec)
bundle exec rake

# Run tests only
bundle exec rspec

# Run unit tests only
bundle exec rspec --tag type:unit

# Run integration tests only
bundle exec rspec --tag type:integration

# Run specific test file
bundle exec rspec spec/skit/serialization/processor/struct_spec.rb

# Run RuboCop
bundle exec rubocop
bundle exec rubocop -a  # Auto-fix

# Run Sorbet type checker
bundle exec srb tc
```

### Tapioca (Type Definition Management)

```bash
# Update all RBI files
bundle exec rake sorbet:update
```

## Architecture

### Core Components

```
lib/skit/
├── skit.rb                          # Main entry point (Skit.serialize, Skit.deserialize)
├── attribute.rb                     # Skit::Attribute for ActiveRecord integration
├── serialization.rb                 # Serialization module setup
├── serialization/
│   ├── registry.rb                  # Processor registry
│   ├── errors.rb                    # Error classes
│   └── processor/                   # Type-specific processors
│       ├── base.rb                  # Base processor class
│       ├── struct.rb                # T::Struct processor
│       ├── array.rb                 # T::Array processor
│       ├── hash.rb                  # T::Hash processor
│       ├── union.rb                 # T.any (union) processor
│       ├── nilable.rb               # T.nilable processor
│       ├── simple_type.rb           # T::Types::Simple wrapper
│       ├── enum.rb                  # T::Enum processor
│       ├── json_schema_const.rb     # Skit::JsonSchema::Types::Const processor
│       └── (primitives)             # string, integer, float, boolean, symbol, date, time
└── json_schema/
    ├── json_schema.rb               # Skit::JsonSchema.generate API
    ├── cli.rb                       # CLI tool
    ├── config.rb                    # Generation options
    ├── schema_analyzer.rb           # JSON Schema parser
    ├── struct_code_generator.rb     # Code generator
    ├── class_name_path.rb           # Class name utilities
    ├── definitions/                 # Internal type definitions
    │   ├── struct.rb
    │   ├── struct_property.rb
    │   ├── property_type.rb
    │   ├── array_property_type.rb
    │   ├── hash_property_type.rb
    │   ├── union_property_type.rb
    │   ├── enum_type.rb             # T::Enum definition
    │   └── const_type.rb            # Const type definition
    └── types/
        └── const.rb                 # Skit::JsonSchema::Types::Const base class
```

### Processor Architecture

Processors handle serialization/deserialization for each type. Each processor has:

- **`self.handles?(type_spec)`**: Returns true if this processor handles the given type
- **`serialize(value)`**: Converts Ruby value to JSON-compatible format
- **`deserialize(value)`**: Converts JSON value to Ruby type
- **`traverse(value, &block)`**: Walks the value tree for validation

Registry finds the appropriate processor based on type_spec.

### Data Flow

```
Application Code
    ↓ (Skit.deserialize)
Processor.deserialize: Hash → T::Struct
    ↓ (held as T::Struct in memory)
    ↓ (Skit.serialize)
Processor.serialize: T::Struct → Hash
    ↓
JSON (for database storage or API response)
```

### ActiveRecord Integration

`Skit::Attribute` is an ActiveModel::Type that:

- **cast(value)**: Hash/Struct → T::Struct (on assignment)
- **serialize(value)**: T::Struct → JSON string (before DB save)
- **deserialize(value)**: JSON string/Hash → T::Struct (on DB load)

## Development Process

### TDD Approach

This project follows TDD (Test-Driven Development):

1. Write tests (clarify specifications)
2. Implement minimum code to pass tests
3. Refactor
4. Run Sorbet type checker

Always create tests before implementing each feature.

### Code Conventions

- **Sorbet sigil**: Add `# typed: strict` to all files (tests use `# typed: false`)
- **frozen_string_literal**: Add `# frozen_string_literal: true` to all files
- **Magic comment order**: `typed` → `frozen_string_literal`
- **String literals**: Use double quotes (`"string"`)
- **Comments and Documentation**: Write all comments and documentation in English
- **Implementation comments**: Avoid comments in implementation (express intent through code)

### Git Commit Guidelines

- **Commit messages**: Write in English
- **Format**: Follow [Conventional Commits](https://www.conventionalcommits.org/)
  - `feat:` for new features
  - `fix:` for bug fixes
  - `refactor:` for code refactoring
  - `chore:` for maintenance tasks
  - `docs:` for documentation changes
  - `test:` for test additions or modifications

### Code Editing

- First try `bundle exec rubocop -a` to auto-fix RuboCop violations in batch. Then manually fix what couldn't be auto-fixed.

### Implementation Process

When adding new features:

1. Write tests under `spec/` (place in appropriate subdirectory)
2. Add minimum implementation
3. Verify tests and type checks pass with `bundle exec rake`
4. Update documentation if needed
5. git commit

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

### Serialization Formats

| Ruby Type | JSON Format |
|-----------|-------------|
| `Date` | ISO 8601 string (`"2025-01-15"`) |
| `Time` | ISO 8601 string with timezone (`"2025-01-15T10:30:00+09:00"`) |
| `Symbol` | string |

## References

- [Sorbet Documentation](https://sorbet.org/)
- [ActiveModel::Attributes API](https://api.rubyonrails.org/classes/ActiveModel/Attributes.html)
- [Tapioca DSL Compilers](https://github.com/Shopify/tapioca)
- [JSON Schema Specification](https://json-schema.org/)
