# typed: strict
# frozen_string_literal: true

require "json"
require "optparse"

module Skit
  module JsonSchema
    class CLI
      extend T::Sig

      sig { params(args: T::Array[String]).returns(Integer) }
      def run(args)
        options = parse_options(args)

        # Exit normally when help or version is requested
        return 0 if options[:help_requested] || options[:version_requested]

        return 1 unless valid_args?(args)

        schema_file = T.must(args.first)
        return 1 unless valid_schema_file?(schema_file)

        process_schema(schema_file, options)
      end

      private

      sig { params(args: T::Array[String]).returns(T::Hash[Symbol, T.untyped]) }
      def parse_options(args)
        options = {
          class_name: nil,
          module_name: nil,
          output_file: nil,
          typed_strictness: "strict",
          help_requested: T.let(false, T::Boolean),
          version_requested: T.let(false, T::Boolean)
        }

        parser = OptionParser.new
        setup_option_parser(parser, options)

        begin
          parser.parse!(args)
        rescue OptionParser::ParseError => e
          warn "Error: #{e.message}"
          warn parser.help
          options[:help_requested] = true
        end

        options
      end

      sig { params(args: T::Array[String]).returns(T::Boolean) }
      def valid_args?(args)
        return true unless args.empty?

        warn "Error: Please provide a JSON Schema file"
        warn "Use --help for usage information"
        false
      end

      sig { params(schema_file: String).returns(T::Boolean) }
      def valid_schema_file?(schema_file)
        return true if File.exist?(schema_file)

        warn "Error: File '#{schema_file}' not found"
        false
      end

      sig { params(schema_file: String, options: T::Hash[Symbol, T.untyped]).returns(Integer) }
      def process_schema(schema_file, options)
        schema_content = File.read(schema_file)
        schema = JSON.parse(schema_content)

        config = Config.new(
          class_name: T.cast(options[:class_name], T.nilable(String)),
          module_name: T.cast(options[:module_name], T.nilable(String)),
          typed_strictness: T.cast(options[:typed_strictness], String)
        )
        analyzer = SchemaAnalyzer.new(T.cast(schema, T::Hash[String, T.untyped]), config)
        module_definition = analyzer.analyze

        generator = CodeGenerator.new(module_definition, config)
        ruby_code = generator.generate

        output_result(ruby_code, options)
        0
      rescue JSON::ParserError => e
        warn "Error: Invalid JSON in '#{schema_file}': #{e.message}"
        1
      rescue Skit::Error => e
        warn "Error: #{e.message}"
        1
      rescue StandardError => e
        warn "Unexpected error: #{e.message}"
        trace = e.backtrace&.join("\n")
        warn trace if trace
        1
      end

      sig { params(ruby_code: String, options: T::Hash[Symbol, T.untyped]).void }
      def output_result(ruby_code, options)
        output_file = T.cast(options[:output_file], T.nilable(String))
        if output_file
          File.write(output_file, ruby_code)
          warn "Generated T::Struct written to #{output_file}"
        else
          puts ruby_code
        end
      end

      sig { params(parser: OptionParser, options: T::Hash[Symbol, T.untyped]).void }
      def setup_option_parser(parser, options)
        parser.banner = "Usage: skit generate [options] <schema_file>"
        parser.separator ""
        parser.separator "Generate Sorbet T::Struct definitions from JSON Schema"
        parser.separator ""
        parser.separator "Options:"

        setup_options(parser, options)
        setup_examples(parser)
      end

      sig { params(parser: OptionParser, options: T::Hash[Symbol, T.untyped]).void }
      def setup_options(parser, options)
        parser.on("-c", "--class-name NAME", "Specify the class name for the generated struct") do |name|
          options[:class_name] = name
        end

        parser.on("-m", "--module-name NAME", "Specify the module name to wrap the generated struct") do |name|
          options[:module_name] = name
        end

        parser.on("-o", "--output FILE", "Write output to specified file instead of stdout") do |file|
          options[:output_file] = file
        end

        parser.on("-t", "--typed LEVEL", Config::VALID_TYPED_LEVELS, "Sorbet typed strictness level",
                  "(#{Config::VALID_TYPED_LEVELS.join(", ")})") do |level|
          options[:typed_strictness] = level
        end

        parser.on("-h", "--help", "Show this help message") do
          puts parser
          options[:help_requested] = true
        end

        parser.on("-v", "--version", "Show version") do
          puts "skit #{Skit::VERSION}"
          options[:version_requested] = true
        end
      end

      sig { params(opts: OptionParser).void }
      def setup_examples(opts)
        opts.separator ""
        opts.separator "Examples:"
        opts.separator "  skit generate user.json"
        opts.separator "  skit generate -c User -o user.rb user_schema.json"
        opts.separator "  skit generate -m MyModule -c User user_schema.json"
        opts.separator "  skit generate -m Foo::Bar -c Baz user_schema.json"
      end
    end
  end
end
