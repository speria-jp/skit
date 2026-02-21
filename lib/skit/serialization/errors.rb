# typed: strict
# frozen_string_literal: true

module Skit
  module Serialization
    class Error < Skit::Error; end
    class UnknownTypeError < Error; end
    class SerializeError < Error; end
    class DeserializeError < Error; end
  end
end
