# typed: strict
# frozen_string_literal: true

module Skit
  module Serialization
    module Processor
      class SimpleType < Base
        extend T::Sig

        sig { override.params(type_spec: T.untyped).returns(T::Boolean) }
        def self.handles?(type_spec)
          type_spec.is_a?(T::Types::Simple)
        end

        sig { params(type_spec: T.untyped, registry: Registry).void }
        def initialize(type_spec, registry:)
          super
          unless type_spec.is_a?(T::Types::Simple)
            raise ArgumentError, "Expected T::Types::Simple, got #{type_spec.class}"
          end

          @raw_type = T.let(type_spec.raw_type, T.untyped)
        end

        sig { override.params(value: T.untyped).returns(T.untyped) }
        def serialize(value)
          processor = @registry.processor_for(@raw_type)
          processor.serialize(value)
        end

        sig { override.params(value: T.untyped).returns(T.untyped) }
        def deserialize(value)
          processor = @registry.processor_for(@raw_type)
          processor.deserialize(value)
        end
      end
    end
  end
end
