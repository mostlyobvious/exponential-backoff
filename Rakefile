#!/usr/bin/env rake

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new do |t|
  t.pattern = "test/*_test.rb"
end

desc "Run tests"
task :default => :test
