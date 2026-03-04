# frozen_string_literal: true

require_relative "lib/skit/version"

Gem::Specification.new do |spec|
  spec.name = "skit"
  spec.version = Skit::VERSION
  spec.authors = ["Speria, inc."]
  spec.email = ["daichi.sakai@speria.jp"]

  spec.summary = "JSON Schema and Sorbet T::Struct integration toolkit"
  spec.description = "Skit provides tools for generating Sorbet T::Struct from JSON Schema, " \
                     "serializing/deserializing between JSON and T::Struct, " \
                     "and integrating with ActiveRecord JSONB columns."
  spec.homepage = "https://github.com/speria-jp/skit"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["documentation_uri"] = spec.homepage
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.glob("lib/**/*") + Dir.glob("exe/*") + %w[README.md LICENSE]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activemodel", ">= 6.0"
  spec.add_dependency "json_schemer"
  spec.add_dependency "sorbet-runtime"

  # Optional: for ActiveRecord integration
  # Users should add activemodel/activerecord to their own Gemfile
end
