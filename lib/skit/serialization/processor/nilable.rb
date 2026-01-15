# typed: strict
# frozen_string_literal: true

module Skit
  module Serialization
    module Processor
      class Nilable < Base
        extend T::Sig

        sig { override.params(type_spec: T.untyped).returns(T::Boolean) }
        def self.handles?(type_spec)
          nilable_type?(type_spec)
        end

        sig { params(type_spec: T.untyped, registry: Registry).void }
        def initialize(type_spec, registry:)
          super
          unless self.class.nilable_type?(type_spec)
            raise ArgumentError,
                  "Expected nilable type, got #{type_spec.class}"
          end

          @inner_type = T.let(extract_inner_type(type_spec), T.untyped)
        end

        sig { override.params(value: T.untyped).returns(T.untyped) }
        def serialize(value)
          return nil if value.nil?

          processor = @registry.processor_for(@inner_type)
          processor.serialize(value)
        end

        sig { override.params(value: T.untyped).returns(T.untyped) }
        def deserialize(value)
          return nil if value.nil?

          processor = @registry.processor_for(@inner_type)
          processor.deserialize(value)
        end

        class << self
          extend T::Sig

          sig { params(type_object: T.untyped).returns(T::Boolean) }
          def nilable_type?(type_object)
            return false unless type_object.is_a?(T::Types::Union)

            types = type_object.types
            has_nil = types.any? { |t| t.is_a?(T::Types::Simple) && t.raw_type == NilClass }
            non_nil_count = types.count { |t| !(t.is_a?(T::Types::Simple) && t.raw_type == NilClass) }

            has_nil && non_nil_count == 1
          end
        end

        private

        sig { params(nilable_type: T.untyped).returns(T.untyped) }
        def extract_inner_type(nilable_type)
          types = nilable_type.types
          non_nil_types = types.reject { |t| t.is_a?(T::Types::Simple) && t.raw_type == NilClass }

          raise ArgumentError, "T.nilable must have exactly one non-nil type" if non_nil_types.length != 1

          non_nil_types.first
        end
      end
    end
  end
end
