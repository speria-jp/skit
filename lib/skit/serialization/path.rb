# typed: strict
# frozen_string_literal: true

module Skit
  module Serialization
    class Path
      extend T::Sig

      Segment = T.type_alias { T.any(::String, ::Integer) }

      sig { params(segments: T::Array[Segment]).void }
      def initialize(segments = [])
        @segments = T.let(segments.freeze, T::Array[Segment])
      end

      sig { params(segment: Segment).returns(Path) }
      def append(segment)
        Path.new(@segments + [segment])
      end

      sig { returns(T::Array[Segment]) }
      attr_reader :segments

      sig { returns(T::Boolean) }
      def empty?
        @segments.empty?
      end

      sig { returns(::String) }
      def to_s
        result = +""
        @segments.each do |segment|
          case segment
          when ::Integer
            result << "[#{segment}]"
          when ::String
            result << "." unless result.empty?
            result << segment
          end
        end
        result.freeze
      end

      sig { returns(::String) }
      def to_json_pointer
        return "" if @segments.empty?

        "/#{@segments.map { |s| s.to_s.gsub("~", "~0").gsub("/", "~1") }.join("/")}"
      end

      sig { params(other: T.untyped).returns(T::Boolean) }
      def ==(other)
        return false unless other.is_a?(Path)

        @segments == other.segments
      end

      sig { returns(::Integer) }
      def hash
        @segments.hash
      end

      sig { params(other: T.untyped).returns(T::Boolean) }
      def eql?(other)
        self == other
      end
    end
  end
end
