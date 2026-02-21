# typed: strict
# frozen_string_literal: true

module Skit
  module Serialization
    module Processor
      class Base
        extend T::Sig
        extend T::Helpers

        abstract!

        sig { overridable.params(type_spec: T.untyped).returns(T::Boolean) }
        def self.handles?(type_spec)
          raise NotImplementedError, "#{self}.handles? must be implemented"
        end

        sig { params(type_spec: T.untyped, registry: Registry).void }
        def initialize(type_spec, registry:)
          @type_spec = type_spec
          @registry = T.let(registry, Registry)
        end

        sig { overridable.params(value: T.untyped, path: Path).returns(T.untyped) }
        def serialize(value, path: Path.new)
          raise NotImplementedError, "#{self.class}#serialize must be implemented"
        end

        sig { overridable.params(value: T.untyped, path: Path).returns(T.untyped) }
        def deserialize(value, path: Path.new)
          raise NotImplementedError, "#{self.class}#deserialize must be implemented"
        end

        sig do
          overridable.params(
            value: T.untyped,
            path: Path,
            blk: T.proc.params(type_spec: T.untyped, node: T.untyped, path: Path).void
          ).void
        end
        def traverse(value, path: Path.new, &blk)
          blk.call(@type_spec, value, path)
        end
      end
    end
  end
end
