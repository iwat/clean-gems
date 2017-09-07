#!/usr/bin/env ruby

require "bundler"
require "find"
require "pry"
require "rubygems/uninstaller"

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
    current[spec.name] ||= {}
    current[spec.name][spec.version] ||= {}
    current[spec.name][spec.version][:spec] = spec
    current[spec.name][spec.version][:usage] ||= []
    current[spec.name][spec.version][:usage] << path
  end
end

all = Gem::Specification.group_by(&:name)

kill_list = []
all.each do |name, specs|
  specs.each do |spec|
    unless current[name]&.key?(spec.version)
      kill_list << spec
    end
  end
end

uninstaller = Gem::Uninstaller.new(nil, abort_on_dependent: true, executables: true)
until kill_list.empty?
  spec = kill_list.shift
  puts "gem uninstall #{spec.name} -v #{spec.version}"

  begin
    uninstaller.uninstall_gem(spec)
  rescue Gem::DependencyRemovalException
    kill_list << spec
  end
end
