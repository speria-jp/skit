# typed: strict
# frozen_string_literal: true

module Skit
  module JsonSchema
    class ClassNamePath
      extend T::Sig

      sig { params(parts: T::Array[String]).void }
      def initialize(parts)
        @parts = T.let(parts.dup, T::Array[String])
      end

      sig { params(title: String).returns(ClassNamePath) }
      def self.title_to_class_name(title)
        # Split existing PascalCase before conversion (APIResponseData -> API_Response_Data)
        with_underscores = title.gsub(/([a-z])([A-Z])/, '\1_\2')
                                .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')

        class_name = NamingUtils.to_pascal_case(with_underscores)

        return default if class_name.empty?

        ClassNamePath.new([class_name])
      end

      sig { params(file_path: T.nilable(String)).returns(ClassNamePath) }
      def self.from_file_path(file_path)
        return default unless file_path

        basename = File.basename(file_path, ".*")
        ClassNamePath.new([NamingUtils.to_pascal_case(basename)])
      end

      sig { returns(ClassNamePath) }
      def self.default
        ClassNamePath.new(["GeneratedClass"])
      end

      sig { returns(T::Array[String]) }
      attr_reader :parts

      sig { params(suffix: String).returns(ClassNamePath) }
      def append(suffix)
        ClassNamePath.new(@parts + [NamingUtils.to_pascal_case(suffix)])
      end

      sig { returns(T.nilable(String)) }
      def parent_class
        return nil if @parts.length < 2

        @parts[0]
      end

      sig { returns(String) }
      def property_name
        T.must(@parts.last)
      end

      sig { returns(String) }
      def to_class_name
        # Generate class name by converting each part to PascalCase (TestUser + address -> TestUserAddress)
        @parts.join
      end
    end
  end
end
