# typed: strict
# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

desc "Run Sorbet type checker"
task :typecheck do
  puts "Running Sorbet type check..."
  system("bundle exec srb tc") || abort("Sorbet type check failed")
end

task default: %i[rubocop spec typecheck]

namespace :sorbet do
  desc "Update all Tapioca RBI files (gems, annotations, dsl)"
  task :update do
    puts "\nUpdating Tapioca annotations..."
    system("bundle exec tapioca annotations") || abort("tapioca annotations failed")

    puts "Updating Tapioca gem RBIs..."
    system("bundle exec tapioca gems") || abort("tapioca gems failed")

    puts "\nUpdating Tapioca DSL RBIs..."
    system("bundle exec tapioca dsl") || abort("tapioca dsl failed")

    puts "\nAll Tapioca RBI files updated successfully!"
  end

  desc "Update Tapioca gem RBIs"
  task :gems do
    system("bundle exec tapioca gems") || abort("tapioca gems failed")
  end

  desc "Update Tapioca annotations"
  task :annotations do
    system("bundle exec tapioca annotations") || abort("tapioca annotations failed")
  end

  desc "Update Tapioca DSL RBIs"
  task :dsl do
    system("bundle exec tapioca dsl") || abort("tapioca dsl failed")
  end

  desc "Run Sorbet type checker"
  task :tc do
    system("bundle exec srb tc") || abort("Sorbet type check failed")
  end
end
