#!/usr/bin/env ruby
# frozen_string_literal: true

# Introspects fastlane plugin actions for a project's Pluginfile.
# Usage: ruby introspect_plugins.rb <project_root>
# Outputs a JSON array of plugin-only action objects to stdout.
# All warnings go to stderr.

require 'json'
require 'rubygems'

# Redirect $stdout → $stderr during all loading so that fastlane UI messages,
# warnings, and progress output don't contaminate our JSON output.
REAL_STDOUT = $stdout.dup
$stdout = $stderr

require 'fastlane'

project_dir = ARGV[0] || Dir.getwd
pluginfile_path = File.join(project_dir, 'fastlane', 'Pluginfile')

unless File.exist?(pluginfile_path)
  REAL_STDOUT.puts '[]'
  exit 0
end

# Parse the Pluginfile for fastlane-plugin-* gem names and optional version constraints.
# Pluginfile is a Gemfile subset: gem 'fastlane-plugin-xxx'[, '>= y.y.y']
plugin_specs = File.readlines(pluginfile_path).filter_map do |line|
  m = line.match(/^\s*gem\s+['"]([^'"]+)['"]\s*(?:,\s*['"]([^'"]+)['"])?/)
  next unless m && m[1].start_with?('fastlane-plugin-')
  { name: m[1], version: m[2] }
end

if plugin_specs.empty?
  REAL_STDOUT.puts '[]'
  exit 0
end

# Load all built-in actions to establish the baseline set.
Fastlane::Actions.load_default_actions

# Stub method_missing so actions that call e.g. `Actions.git_branch` inside
# available_options default_value don't raise NoMethodError during introspection.
Fastlane::Actions.instance_eval do
  def method_missing(name, *args)
    nil
  end
  def respond_to_missing?(name, include_private = false)
    true
  end
end

base_constants = Fastlane::Actions.constants.to_set

# Load each plugin gem by activating it and requiring its main file.
# Convention: fastlane-plugin-foo_bar requires as 'fastlane/plugin/foo_bar'.
plugin_specs.each do |spec_info|
  gem_name = spec_info[:name]
  plugin_name = gem_name.sub('fastlane-plugin-', '')
  require_path = "fastlane/plugin/#{plugin_name}"

  begin
    spec = if spec_info[:version]
             Gem::Specification.find_by_name(gem_name, spec_info[:version])
           else
             Gem::Specification.find_by_name(gem_name)
           end

    spec.load_paths.each { |p| $LOAD_PATH.unshift(p) unless $LOAD_PATH.include?(p) }
    require require_path
  rescue Gem::MissingSpecError => e
    $stderr.puts "Warning: gem not installed — #{gem_name}: #{e}"
  rescue LoadError => e
    $stderr.puts "Warning: could not load #{require_path}: #{e}"
  rescue => e
    $stderr.puts "Warning: error loading #{gem_name}: #{e}"
  end
end

# Collect only newly registered action constants (plugin actions).
plugin_constants = Fastlane::Actions.constants.to_set - base_constants

def serialize_options(klass)
  opts = klass.available_options rescue nil
  return [] unless opts.is_a?(Array)

  opts.filter_map do |opt|
    next unless opt.respond_to?(:key)

    data_type = opt.data_type rescue nil
    type_str = case data_type
               when Class  then data_type.name
               when Symbol then data_type.to_s
               when nil    then ''
               else             data_type.to_s
               end

    default_val = begin
      dv = opt.default_value
      dv.nil? ? nil : dv.inspect
    rescue
      nil
    end

    {
      key:         opt.key.to_s,
      description: opt.description.to_s,
      type:        type_str,
      default:     default_val,
      optional:    opt.optional
    }
  rescue
    nil
  end
end

actions = plugin_constants.filter_map do |const_name|
  klass = Fastlane::Actions.const_get(const_name) rescue next
  next unless klass.is_a?(Class) && klass < Fastlane::Action

  {
    name:         (klass.action_name rescue const_name.to_s.downcase).to_s,
    description:  (klass.description rescue '').to_s,
    return_value: (klass.return_value rescue nil).to_s,
    options:      serialize_options(klass)
  }
rescue
  nil
end

REAL_STDOUT.puts JSON.generate(actions)
