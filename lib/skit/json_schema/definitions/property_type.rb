# typed: strict
# frozen_string_literal: true

module Skit
  module JsonSchema
    module Definitions
      class PropertyType
        extend T::Sig

        sig { returns(String) }
        attr_reader :base_type

        sig { returns(T::Boolean) }
        attr_reader :nullable

        sig do
          params(
            base_type: String,
            nullable: T::Boolean
          ).void
        end
        def initialize(base_type:, nullable: false)
          @base_type = base_type
          @nullable = nullable
        end

        sig { returns(String) }
        def to_sorbet_type
          nullable ? "T.nilable(#{@base_type})" : @base_type
        end
      end
    end
  end
end
