# typed: strict
# frozen_string_literal: true

module Skit
  module JsonSchema
    class Config
      extend T::Sig

      VALID_TYPED_LEVELS = T.let(%w[ignore false true strict strong].freeze, T::Array[String])

      sig { returns(T.nilable(String)) }
      attr_reader :class_name

      sig { returns(T.nilable(String)) }
      attr_reader :module_name

      sig { returns(String) }
      attr_reader :typed_strictness

      sig { params(class_name: T.nilable(String), module_name: T.nilable(String), typed_strictness: String).void }
      def initialize(class_name: nil, module_name: nil, typed_strictness: "strict")
        @class_name = T.let(validate_class_name(class_name), T.nilable(String))
        @module_name = T.let(validate_module_name(module_name), T.nilable(String))
        @typed_strictness = T.let(validate_typed_strictness(typed_strictness), String)
      end

      private

      sig { params(class_name: T.nilable(String)).returns(T.nilable(String)) }
      def validate_class_name(class_name)
        return nil if class_name.nil?

        unless class_name.match?(/\A[A-Z][a-zA-Z0-9_]*\z/)
          raise ArgumentError,
                "Invalid class name: #{class_name.inspect}. Must start with uppercase letter " \
                "and contain only alphanumeric characters and underscores."
        end

        class_name
      end

      sig { params(module_name: T.nilable(String)).returns(T.nilable(String)) }
      def validate_module_name(module_name)
        return nil if module_name.nil?

        # Support Foo::Bar::Baz format
        unless module_name.match?(/\A[A-Z][a-zA-Z0-9_]*(?:::[A-Z][a-zA-Z0-9_]*)*\z/)
          raise ArgumentError,
                "Invalid module name: #{module_name.inspect}. Must be valid Ruby module name " \
                "(e.g., 'MyModule' or 'Foo::Bar::Baz')."
        end

        module_name
      end

      sig { params(level: String).returns(String) }
      def validate_typed_strictness(level)
        unless VALID_TYPED_LEVELS.include?(level)
          raise ArgumentError,
                "Invalid typed strictness level: #{level}. Valid options are: #{VALID_TYPED_LEVELS.join(", ")}"
        end

        level
      end
    end
  end
end
