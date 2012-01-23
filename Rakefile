# -*- ruby -*-
require 'bundler/setup'
require 'rake'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = ENV['RSPEC_OPTS']
end

task :test => :spec
task :default => :test

desc "Opens console with loaded env."
task :console do
  require File.expand_path("../init", __FILE__)
  require 'irb'
  ARGV.clear
  IRB.start
end
