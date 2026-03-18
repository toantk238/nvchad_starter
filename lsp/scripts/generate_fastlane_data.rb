#!/usr/bin/env ruby
# frozen_string_literal: true

# Introspects installed fastlane gems and generates lsp/data/fastlane_api.json
# Run from any fastlane project: ruby /path/to/scripts/generate_fastlane_data.rb

require 'fileutils'
require 'json'
require 'fastlane'

# Load all built-in actions (not loaded by default on `require 'fastlane'`)
Fastlane::Actions.load_default_actions

# Some actions call `Actions.git_branch` or similar helpers as default_value
# expressions inside available_options, which raises NoMethodError outside a
# live lane context.  Stub method_missing so those calls return nil instead
# of aborting the entire options array.
Fastlane::Actions.instance_eval do
  def method_missing(name, *args)
    nil
  end
  def respond_to_missing?(name, include_private = false)
    true
  end
end

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Build a readable parameter string from Method#parameters pairs.
def build_signature_params(unbound_or_method)
  unbound_or_method.parameters.filter_map do |type, name|
    next if type == :block || name.nil?

    case type
    when :req                then name.to_s
    when :opt                then "#{name} = nil"
    when :rest               then "*#{name}"
    when :keyreq             then "#{name}:"
    when :key                then "#{name}: nil"
    when :keyrest            then "**#{name}"
    end
  end.join(', ')
end

# ---------------------------------------------------------------------------
# Output skeleton
# ---------------------------------------------------------------------------

output = {
  actions: [],
  modules: {
    'UI' => [],
    'Actions' => []
  },
  dsl_keywords: []
}

# ---------------------------------------------------------------------------
# Actions — already fully programmatic
# ---------------------------------------------------------------------------

Fastlane::Actions.constants.each do |const_name|
  begin
    klass = Fastlane::Actions.const_get(const_name)
    next unless klass.is_a?(Class) && klass < Fastlane::Action

    action_name = begin
      klass.action_name
    rescue StandardError
      const_name.to_s.downcase
    end

    description = begin
      klass.description
    rescue StandardError
      ''
    end

    return_value = begin
      klass.return_value
    rescue StandardError
      nil
    end

    options = []
    begin
      available_options = klass.available_options
      if available_options.is_a?(Array)
        available_options.each do |opt|
          next unless opt.respond_to?(:key)

          data_type = opt.data_type
          type_str = case data_type
                     when Class  then data_type.name
                     when Symbol then data_type.to_s
                     when nil    then ''
                     else             data_type.to_s
                     end

          default_val = begin
            dv = opt.default_value
            dv.nil? ? nil : dv.inspect
          rescue StandardError
            nil
          end

          options << {
            key: opt.key.to_s,
            description: opt.description.to_s,
            type: type_str,
            default: default_val,
            optional: opt.optional
          }
        end
      end
    rescue StandardError
      # ignore options extraction errors
    end

    output[:actions] << {
      name: action_name.to_s,
      description: description.to_s,
      return_value: return_value.to_s,
      options: options
    }
  rescue StandardError
    # ignore action extraction errors
  end
end

# ---------------------------------------------------------------------------
# UI — reflect on FastlaneCore::Interface
#
# Names + parameter signatures come entirely from reflection.
# Descriptions live in a small lookup hash because they are human prose
# not stored anywhere in the gem's metadata.
# ---------------------------------------------------------------------------

# UI_DESCRIPTIONS = {
#   'user_error!'              => 'Raise a user-facing error and abort the lane',
#   'message'                  => 'Print a message to the user',
#   'success'                  => 'Print a success message',
#   'error'                    => 'Print an error message',
#   'important'                => 'Print an important/warning message',
#   'verbose'                  => 'Print a verbose/debug message',
#   'input'                    => 'Ask the user for text input',
#   'confirm'                  => 'Ask the user for a yes/no confirmation',
#   'password'                 => 'Ask the user for a password (hidden input)',
#   'crash!'                   => 'Crash with an error message and backtrace',
#   'header'                   => 'Print a section header',
#   'deprecate_output_message' => 'Print a deprecation warning'
# }.freeze

begin
  interface = FastlaneCore::Interface
  ui_methods = interface.instance_methods(false).map(&:to_s).sort

  output[:modules]['UI'] = ui_methods.map do |name|
    unbound = interface.instance_method(name.to_sym)
    params  = build_signature_params(unbound)
    {
      name: name,
      # description: UI_DESCRIPTIONS.fetch(name, ''),
      signature: "UI.#{name}(#{params})"
    }
  end
rescue StandardError => e
  warn "Warning: could not reflect on FastlaneCore::Interface: #{e}"
end

# ---------------------------------------------------------------------------
# Actions module helpers — reflect on Fastlane::Actions singleton methods
#
# We exclude methods inherited from ancestors (Module, Object, Kernel, etc.)
# to keep only methods that fastlane itself defines on the Actions namespace.
# ---------------------------------------------------------------------------

ACTIONS_DESCRIPTIONS = {
  'sh'           => 'Run a shell command',
  'lane_context' => 'Access shared lane context values'
}.freeze

begin
  # public_methods(false) returns only methods defined directly on the object,
  # not inherited ones — exactly what we want.
  actions_methods = Fastlane::Actions.public_methods(false).map(&:to_s).sort

  output[:modules]['Actions'] = actions_methods.map do |name|
    m      = Fastlane::Actions.method(name.to_sym)
    params = build_signature_params(m)
    {
      name: name,
      description: ACTIONS_DESCRIPTIONS.fetch(name, ''),
      signature: "Actions.#{name}(#{params})"
    }
  end
rescue StandardError => e
  warn "Warning: could not reflect on Fastlane::Actions: #{e}"
end

# ---------------------------------------------------------------------------
# DSL keywords
#
# Source: Fastlane::FastFile.instance_methods(false) — the class whose
# instance is the eval context when fastlane loads a Fastfile.
# Internal implementation methods are excluded via FASTFILE_INTERNAL_METHODS.
#
# Snippets are tab-stop templates — structural knowledge that has no
# machine-readable representation in the gem source, so we keep them here.
# ---------------------------------------------------------------------------

DSL_SNIPPETS = {
  'lane'                 => "lane :${1:name} do |options|\n  ${2:# actions}\nend",
  'platform'             => "platform :${1:ios} do\n  ${2:# lanes}\nend",
  'before_all'           => "before_all do |lane, options|\n  ${1:# setup}\nend",
  'before_each'          => "before_each do |lane, options|\n  ${1:# setup}\nend",
  'after_all'            => "after_all do |lane, options|\n  ${1:# teardown}\nend",
  'after_each'           => "after_each do |lane, options|\n  ${1:# teardown}\nend",
  'error'                => "error do |lane, exception, options|\n  ${1:# handle error}\nend",
  'desc'                 => 'desc "${1:description}"',
  'private_lane'         => "private_lane :${1:name} do |options|\n  ${2:# actions}\nend",
  'override_lane'        => "override_lane :${1:name} do |options|\n  ${2:# actions}\nend",
  'sh'                   => 'sh("${1:command}")',
  'import'               => 'import("${1:path}")',
  'import_from_git'      => "import_from_git(\n  url: \"${1:git_url}\",\n  path: \"${2:fastlane/Fastfile}\"\n)",
  'fastlane_require'     => 'fastlane_require "${1:gem_name}"',
  'actions_path'         => 'actions_path("${1:path}")',
  'say'                  => 'say("${1:message}")'
}.freeze

DSL_DESCRIPTIONS = {
  'lane'                 => 'Define a lane',
  'platform'             => 'Define a platform-specific lane group',
  'before_all'           => 'Block executed before any lane',
  'before_each'          => 'Block executed before each lane',
  'after_all'            => 'Block executed after any lane',
  'after_each'           => 'Block executed after each lane',
  'error'                => 'Block executed when an error occurs',
  'desc'                 => 'Add a description to the next lane',
  'private_lane'         => 'Define a private lane (not callable from CLI)',
  'override_lane'        => 'Override an existing lane',
  'sh'                   => 'Run a shell command',
  'import'               => 'Import another Fastfile',
  'import_from_git'      => 'Import a Fastfile from a git repository',
  'fastlane_require'     => 'Require a gem at runtime',
  'actions_path'         => 'Add a custom actions directory to the search path',
  'say'                  => 'Speak a message aloud using the system text-to-speech'
}.freeze

# Methods defined on FastFile that are implementation details, not user-facing DSL.
FASTFILE_INTERNAL_METHODS = %w[
  initialize parse parsing_binding
  runner runner=
  current_platform current_platform=
  method_missing is_platform_block?
  desc_collection generated_fastfile_id
  find_tag get_tags
  test action_launched action_completed
  puts
].freeze

dsl_method_names =
  begin
    Fastlane::FastFile
      .instance_methods(false)
      .map(&:to_s)
      .reject { |m| FASTFILE_INTERNAL_METHODS.include?(m) }
      .sort
  rescue NameError => e
    warn "Warning: Fastlane::FastFile not found (#{e}); falling back to snippet keys"
    DSL_SNIPPETS.keys
  end

output[:dsl_keywords] = dsl_method_names.map do |name|
  {
    name: name,
    snippet: DSL_SNIPPETS.fetch(name, name),
    description: DSL_DESCRIPTIONS.fetch(name, '')
  }
end

# ---------------------------------------------------------------------------
# Write output
# ---------------------------------------------------------------------------

data_dir    = File.join(File.dirname(File.realpath(__FILE__)), '..', 'data')
FileUtils.mkdir_p(data_dir)
output_file = File.join(data_dir, 'fastlane_api.json')
File.write(output_file, JSON.pretty_generate(output))

puts "Generated #{output_file}"
puts "  Actions:         #{output[:actions].length}"
puts "  UI methods:      #{output[:modules]['UI'].length}"
puts "  Actions methods: #{output[:modules]['Actions'].length}"
puts "  DSL keywords:    #{output[:dsl_keywords].length}"
