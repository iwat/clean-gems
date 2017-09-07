#!/usr/bin/env ruby

require "bundler"
require "find"

if ARGV.size == 0
  puts "Generate rm script for cleaning all unused Gems"
  puts
  puts "Usage:"
  puts "  ./main.rb base_directory"
  exit 1
end

current = {}

Find.find('..') do |path|
  next if path !~ /Gemfile.lock$/

  parser = Bundler::LockfileParser.new(Bundler.read_file(path))
  parser.specs.each do |spec|
    current[spec.name] ||= Set.new
    current[spec.name].add(spec.version)
  end
end

all = Gem::Specification.group_by(&:name)

all.each do |name, specs|
  specs.each do |spec|
    unless current[name]&.include?(spec.version)
      puts "rm -rf #{spec.gem_dir}"
    end
  end
end
