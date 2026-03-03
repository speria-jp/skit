# typed: strict
# frozen_string_literal: true

module Skit
  module Serialization
    class Error < Skit::Error
      extend T::Sig

      sig { returns(Path) }
      attr_reader :path

      sig { params(message: ::String, path: Path).void }
      def initialize(message = "", path: Path.new)
        @path = T.let(path, Path)
        super(path.empty? ? message : "#{message} (at #{path})")
      end
    end

    class UnknownTypeError < Error; end
    class SerializeError < Error; end
    class DeserializeError < Error; end
  end
end
