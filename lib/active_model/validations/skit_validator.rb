# typed: strict
# frozen_string_literal: true

module ActiveModel
  module Validations
    class SkitValidator < ActiveModel::EachValidator
      extend T::Sig

      sig { params(record: T.untyped, attribute: T.any(String, Symbol), value: T.untyped).void }
      def validate_each(record, attribute, value)
        return if value.nil?

        attribute_type = get_skit_attribute_type(record, attribute)
        return unless attribute_type

        processor = attribute_type.processor
        processor.traverse(value, path: "") do |_type_spec, node, path|
          next unless node.respond_to?(:valid?)
          next if node.valid?

          node.errors.each do |error|
            error_key = build_error_key(attribute, path, error.attribute)
            record.errors.add(error_key, error.message)
          end
        end
      end

      private

      sig { params(attribute: T.any(::String, Symbol), path: ::String, error_attribute: Symbol).returns(::String) }
      def build_error_key(attribute, path, error_attribute)
        if path.empty?
          "#{attribute}.#{error_attribute}"
        else
          "#{attribute}.#{path}.#{error_attribute}"
        end
      end

      sig { params(record: T.untyped, attribute: T.any(String, Symbol)).returns(T.nilable(Skit::Attribute)) }
      def get_skit_attribute_type(record, attribute)
        return nil unless record.class.respond_to?(:attribute_types)

        attribute_type = record.class.attribute_types[attribute.to_s]
        attribute_type.is_a?(Skit::Attribute) ? attribute_type : nil
      end
    end
  end
end
