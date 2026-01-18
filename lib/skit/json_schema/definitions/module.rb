# typed: strict
# frozen_string_literal: true

module Skit
  module JsonSchema
    module Definitions
      class Module
        extend T::Sig

        sig { returns(Struct) }
        attr_reader :root_struct

        sig { returns(T::Array[Struct]) }
        attr_reader :nested_structs

        sig { returns(T::Array[ConstType]) }
        attr_reader :const_types

        sig { returns(T::Array[EnumType]) }
        attr_reader :enum_types

        sig do
          params(
            root_struct: Struct,
            nested_structs: T::Array[Struct],
            const_types: T::Array[ConstType],
            enum_types: T::Array[EnumType]
          ).void
        end
        def initialize(root_struct:, nested_structs: [], const_types: [], enum_types: [])
          @root_struct = root_struct
          @nested_structs = nested_structs
          @const_types = const_types
          @enum_types = enum_types
        end

        sig { returns(T::Boolean) }
        def const_types?
          !@const_types.empty?
        end

        sig { returns(T::Boolean) }
        def enum_types?
          !@enum_types.empty?
        end

        sig { returns(T::Boolean) }
        def nested_structs?
          !@nested_structs.empty?
        end
      end
    end
  end
end
