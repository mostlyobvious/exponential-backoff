#!/usr/bin/env rake

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new do |t|
  t.pattern = "test/*_test.rb"
end

desc "Run mutation tests"
task :mutate do
  require 'mutant'

  Kernel.exit(
    Mutant::CLI.run(
      %q[
        --include lib
        --require exponential_backoff.rb
        --use minitest
        -- ExponentialBackoff*
      ].split
    )
  )
end

desc "Run tests"
task :default => :test
