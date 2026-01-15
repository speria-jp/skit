# typed: strict
# frozen_string_literal: true

module Skit
  module Serialization
    class Registry
      extend T::Sig

      sig { void }
      def initialize
        @processors = T.let([], T::Array[T.class_of(Processor::Base)])
      end

      sig { params(processor_class: T.class_of(Processor::Base)).void }
      def register(processor_class)
        @processors << processor_class
      end

      sig { params(type_spec: T.untyped).returns(T.class_of(Processor::Base)) }
      def find_processor(type_spec)
        processor_class = @processors.find { |p| p.handles?(type_spec) }
        raise UnknownTypeError, "No processor for #{type_spec}" unless processor_class

        processor_class
      end

      sig { params(type_spec: T.untyped).returns(Processor::Base) }
      def processor_for(type_spec)
        find_processor(type_spec).new(type_spec, registry: self)
      end
    end
  end
end
