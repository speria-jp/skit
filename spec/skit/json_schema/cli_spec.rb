# typed: false
# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "fileutils"

RSpec.describe Skit::JsonSchema::CLI, type: :unit do
  let(:cli) { described_class.new }

  describe "#run" do
    let(:valid_schema) do
      {
        "type" => "object",
        "properties" => {
          "name" => { "type" => "string" }
        }
      }.to_json
    end

    context "with help flag" do
      it "returns 0 and shows help" do
        expect { cli.run(["--help"]) }.to output(/Usage:/).to_stdout
      end
    end

    context "with version flag" do
      it "returns 0 and shows version" do
        expect { cli.run(["--version"]) }.to output(/skit #{Skit::VERSION}/).to_stdout
      end
    end

    context "with no arguments" do
      it "returns 1 and shows error" do
        expect { cli.run([]) }.to output(/Error: Please provide a JSON Schema file/).to_stderr
        expect(cli.run([])).to eq(1)
      end
    end

    context "with non-existent file" do
      it "returns 1 and shows error" do
        expect { cli.run(["nonexistent.json"]) }.to output(/Error: File 'nonexistent.json' not found/).to_stderr
        expect(cli.run(["nonexistent.json"])).to eq(1)
      end
    end

    context "with valid schema file" do
      let(:schema_file) do
        file = Tempfile.new(["schema", ".json"])
        file.write(valid_schema)
        file.close
        file.path
      end

      after do
        FileUtils.rm_f(schema_file)
      end

      it "returns 0 and outputs generated code" do
        expect { cli.run([schema_file]) }.to output(/class GeneratedClass < T::Struct/).to_stdout
        expect(cli.run([schema_file])).to eq(0)
      end

      it "uses class name option" do
        expect { cli.run(["-c", "User", schema_file]) }.to output(/class User < T::Struct/).to_stdout
      end

      it "uses module name option" do
        expect { cli.run(["-m", "MyModule", schema_file]) }.to output(/module MyModule/).to_stdout
      end

      it "writes to output file" do
        output_file = Tempfile.new(["output", ".rb"])
        output_path = output_file.path
        output_file.close

        cli.run(["-o", output_path, schema_file])

        content = File.read(output_path)
        expect(content).to include("class GeneratedClass < T::Struct")

        FileUtils.rm_f(output_path)
      end
    end

    context "with invalid JSON file" do
      let(:invalid_json_file) do
        file = Tempfile.new(["invalid", ".json"])
        file.write("{ invalid json }")
        file.close
        file.path
      end

      after do
        FileUtils.rm_f(invalid_json_file)
      end

      it "returns 1 and shows JSON error" do
        expect { cli.run([invalid_json_file]) }.to output(/Error: Invalid JSON/).to_stderr
        expect(cli.run([invalid_json_file])).to eq(1)
      end
    end

    context "with invalid schema" do
      let(:invalid_schema_file) do
        file = Tempfile.new(["invalid_schema", ".json"])
        file.write('{"type": "string"}')
        file.close
        file.path
      end

      after do
        FileUtils.rm_f(invalid_schema_file)
      end

      it "returns 1 and shows schema error" do
        expect { cli.run([invalid_schema_file]) }.to output(/Error:/).to_stderr
        expect(cli.run([invalid_schema_file])).to eq(1)
      end
    end
  end
end
