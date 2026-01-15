# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-01-15

### Added

- Initial release
- **JSON Schema to T::Struct code generation**
  - CLI tool (`skit generate`)
  - Programmatic API (`Skit::JsonSchema.generate`)
  - Support for `$ref` references within same file
  - Support for nested objects, arrays, and union types (`anyOf`/`oneOf`)
  - Date and DateTime format support
- **T::Struct serialization/deserialization**
  - `Skit.serialize(struct)` - T::Struct to Hash
  - `Skit.deserialize(hash, type)` - Hash to T::Struct
  - TypeProcessor architecture for extensible type handling
  - Support for primitives: String, Integer, Float, Boolean, Symbol, Date, Time
  - Support for complex types: T::Array, T::Hash, T.nilable, T.any (Union)
- **ActiveRecord JSONB integration**
  - `Skit::Attribute[Type]` for typed attributes
  - PostgreSQL, MySQL, and SQLite support
  - Transparent conversion between T::Struct and JSON
- **Validation**
  - ActiveModel::Validations integration
  - SkitValidator for nested struct validation
  - Indexed error messages for arrays (e.g., `items.[0].name`)

[unreleased]: https://github.com/speria-jp/skit/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/speria-jp/skit/releases/tag/v0.1.0
