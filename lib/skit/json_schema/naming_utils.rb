# typed: strict
# frozen_string_literal: true

module Skit
  module JsonSchema
    module NamingUtils
      extend T::Sig

      sig { params(value: String).returns(String) }
      def self.to_pascal_case(value)
        value.gsub(/[^a-zA-Z0-9]+/, "_")
             .gsub(/^_+|_+$/, "")
             .split("_")
             .map(&:capitalize)
             .join
      end

      sig { params(value: T.any(Integer, Float)).returns(String) }
      def self.number_to_name(value)
        num_str = value.to_s.gsub("-", "Minus").gsub(".", "Dot")
        "Val#{num_str}"
      end
    end
  end
end
