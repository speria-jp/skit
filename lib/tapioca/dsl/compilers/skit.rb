# typed: strict
# frozen_string_literal: true

return unless defined?(Tapioca::Dsl::Compiler)
return unless defined?(ActiveRecord::Base)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::Skit` decorates RBI files for ActiveRecord models
      # that use `Skit::Attribute` for typed JSON attributes.
      #
      # For example, with the following model:
      #
      # ~~~rb
      # class Address < T::Struct
      #   const :city, String
      #   const :zip, T.nilable(String)
      # end
      #
      # class Customer < ActiveRecord::Base
      #   attribute :address, Skit::Attribute[Address]
      # end
      # ~~~
      #
      # this compiler will produce an RBI file with the following content:
      # ~~~rbi
      # # typed: strong
      #
      # class Customer
      #   sig { returns(Address) }
      #   def address; end
      #
      #   sig { params(value: T.untyped).returns(Address) }
      #   def address=(value); end
      # end
      # ~~~
      #: [ConstantType = T.class_of(::ActiveRecord::Base)]
      class Skit < Compiler
        extend T::Sig

        # @override
        #: -> void
        def decorate
          attributes = constant.attribute_types.select { |_name, type| skit_attribute_type?(type) }

          return if attributes.empty?

          root.create_path(constant) do |klass|
            attributes.each do |attr_name, type|
              create_attribute_methods(klass, attr_name, type)
            end
          end
        end

        class << self
          extend T::Sig

          # @override
          #: -> Enumerable[Module]
          def gather_constants
            descendants = ActiveRecord::Base.descendants.reject(&:abstract_class?)

            descendants.select do |klass|
              klass.attribute_types.values.any? { |type| skit_attribute_type?(type) }
            rescue ActiveRecord::StatementInvalid
              false
            end
          end

          #: (untyped type) -> bool
          def skit_attribute_type?(type)
            type.is_a?(::Skit::Attribute)
          end
        end

        private

        #: (untyped type) -> bool
        def skit_attribute_type?(type)
          self.class.skit_attribute_type?(type)
        end

        #: (RBI::Scope klass, String attr_name, untyped type) -> void
        def create_attribute_methods(klass, attr_name, type)
          return unless type.is_a?(::Skit::Attribute)

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
