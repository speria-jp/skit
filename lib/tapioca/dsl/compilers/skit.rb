# typed: false
# frozen_string_literal: true

return unless defined?(Tapioca)
return unless defined?(ActiveRecord::Base)

require "tapioca/dsl"

module Tapioca
  module Dsl
    module Compilers
      class Skit < Tapioca::Dsl::Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.class_of(ActiveRecord::Base) } }

        sig { override.void }
        def decorate
          attributes = T.let(
            constant.attribute_types.select { |_name, type| skit_attribute_type?(type) },
            T::Hash[String, ActiveModel::Type::Value]
          )

          return if attributes.empty?

          root.create_path(constant) do |klass|
            attributes.each do |attr_name, type|
              create_attribute_methods(klass, attr_name, type)
            end
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def self.gather_constants
          descendants = T.cast(
            ActiveRecord::Base.descendants.reject(&:abstract_class?),
            T::Array[T.class_of(ActiveRecord::Base)]
          )

          descendants.select do |klass|
            klass.attribute_types.values.any? { |type| skit_attribute_type?(type) }
          rescue ActiveRecord::StatementInvalid
            false
          end
        end

        class << self
          def skit_attribute_type?(type)
            type.is_a?(::Skit::Attribute)
          end
        end

        private

        sig { params(type: ActiveModel::Type::Value).returns(T::Boolean) }
        def skit_attribute_type?(type)
          self.class.skit_attribute_type?(type)
        end

        sig { params(klass: RBI::Scope, attr_name: String, type: ActiveModel::Type::Value).void }
        def create_attribute_methods(klass, attr_name, type)
          return unless type.is_a?(::Skit::Attribute)

          create_skit_attribute_methods(klass, attr_name, type)
        end

        sig { params(klass: RBI::Scope, attr_name: String, type: ::Skit::Attribute).void }
        def create_skit_attribute_methods(klass, attr_name, type)
          type_spec = type.instance_variable_get(:@type_spec)
          type_string = type_spec.name

          klass.create_method(
            attr_name,
            return_type: type_string
          )

          klass.create_method(
            "#{attr_name}=",
            parameters: [create_param("value", type: "T.untyped")],
            return_type: type_string
          )
        end
      end
    end
  end
end
