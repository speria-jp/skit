# typed: false
# frozen_string_literal: true

begin
  require "tapioca"
  require "tapioca/dsl"
rescue LoadError
  # Skip if tapioca is not available
end

return unless defined?(Tapioca)

module TapiocaHelpers
  def setup_tapioca_environment
    @temp_dir = Dir.mktmpdir
    @original_load_path = $LOAD_PATH.dup
    $LOAD_PATH.unshift(@temp_dir)
    @test_constants = []
  end

  def cleanup_tapioca_environment
    $LOAD_PATH.replace(@original_load_path) if @original_load_path
    FileUtils.rm_rf(@temp_dir) if @temp_dir
    cleanup_constants
  end

  def register_test_constant(const_name)
    @test_constants ||= []
    @test_constants << const_name.to_sym
  end

  def cleanup_constants
    return unless @test_constants

    @test_constants.each do |const_name|
      next unless Object.const_defined?(const_name)

      # rubocop:disable RSpec/RemoveConst
      Object.send(:remove_const, const_name)
      # rubocop:enable RSpec/RemoveConst
    rescue NameError
      next
    end

    @test_constants = []
  end

  def add_ruby_file(filename, content)
    file_path = File.join(@temp_dir, filename)
    File.write(file_path, content)

    # rubocop:disable Sorbet/ConstantsFromStrings
    constants_before = Object.constants

    load file_path

    new_constants = Object.constants - constants_before
    # rubocop:enable Sorbet/ConstantsFromStrings
    new_constants.each { |const_name| register_test_constant(const_name) }
  end

  def rbi_for(klass)
    require "rbi"

    constants = Tapioca::Dsl::Compilers::Skit.gather_constants
    return "# typed: strong\n" unless constants.include?(klass)

    rbi_tree = RBI::Tree.new

    pipeline = Tapioca::Dsl::Pipeline.new(
      requested_constants: [klass],
      requested_compilers: [Tapioca::Dsl::Compilers::Skit]
    )

    compiler = Tapioca::Dsl::Compilers::Skit.new(pipeline, rbi_tree, klass)
    compiler.decorate

    rbi_file = RBI::File.new(strictness: "strong")
    rbi_file.root = rbi_tree

    rbi_file.string
  rescue StandardError => e
    warn "Error in rbi_for: #{e.class}: #{e.message}"
    warn e.backtrace.first(5).join("\n")
    "# typed: strong\n"
  end
end

RSpec.configure do |config|
  config.include TapiocaHelpers, type: :tapioca_integration

  config.before(:each, type: :tapioca_integration) do
    ActiveRecord::Base.establish_connection(
      adapter: "sqlite3",
      database: ":memory:"
    )

    setup_tapioca_environment
  end

  config.after(:each, type: :tapioca_integration) do
    cleanup_tapioca_environment

    ActiveRecord::Base.connection.disconnect! if ActiveRecord::Base.connected?
  end
end
