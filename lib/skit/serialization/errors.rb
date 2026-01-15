# typed: strict
# frozen_string_literal: true

module Skit
  module Serialization
    class UnknownTypeError < StandardError; end
    class TypeMismatchError < StandardError; end
    class DeserializationError < StandardError; end
  end
end
