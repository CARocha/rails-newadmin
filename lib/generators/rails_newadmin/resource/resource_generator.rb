require "rails/generators"

module RailsNewadmin
  module Generators
    class ResourceGenerator < Rails::Generators::NamedBase
      class_option :permit, type: :array, default: []
      class_option :single_site, type: :boolean, default: false

      def generate_resource
        model = class_name.safe_constantize
        raise Thor::Error, "Expected an existing Active Record model" unless model && model < ActiveRecord::Base
        sensitive = model.respond_to?(:encrypted_attributes) ? Array(model.encrypted_attributes).map(&:to_s) : []
        columns = model.column_names.reject { |name| sensitive.include?(name) || name.match?(/password|digest|token|secret|encrypted/) }
        writable = columns - [ model.primary_key, "created_at", "updated_at", "lock_version" ]
        permit = options[:permit].map(&:to_s)
        raise Thor::Error, "permit contains unknown or sensitive fields" unless (permit - writable).empty?
        fields = writable.first(8)
        @resource_path = "app/admin/resources/#{file_path}_resource.rb"
        @policy_path = "app/policies/#{file_path}_admin_policy.rb"
        if [ @resource_path, @policy_path ].any? { |path| File.exist?(File.join(destination_root, path)) }
          raise Thor::Error, "Resource or policy already exists; edit it instead of overwriting"
        end
        body = [ "model #{class_name.inspect}", "key #{file_path.tr('/', '_').pluralize.inspect}",
          "columns #{columns.first(6).map { |name| ":#{name}" }.join(', ')}",
          "fields #{fields.map { |name| ":#{name}" }.join(', ')}",
          "permit #{permit.map { |name| ":#{name}" }.join(', ')}", "policy #{"#{class_name}AdminPolicy".inspect}" ]
        create_file @resource_path, wrap_class("#{class_name.demodulize}Resource", "RailsNewadmin::Resource", body)
        policy = if options[:single_site]
          [ "def allowed?(actor:, action:, record: nil) = true", "def scope(actor:, relation:) = relation.all",
            "def permitted_attributes(actor:, action:, record: nil) = resource.permitted_fields" ]
        else
          [ "# Closed by default. Inherit the safe policy until a scoped policy is supplied." ]
        end
        create_file @policy_path, wrap_class("#{class_name.demodulize}AdminPolicy", "RailsNewadmin::Policy", policy)
      end

      private

      def wrap_class(name, parent, body)
        modules = class_name.deconstantize.split("::").reject(&:empty?)
        lines = modules.each_with_index.map { |part, index| "#{'  ' * index}module #{part}" }
        indent = "  " * modules.length
        lines << "#{indent}class #{name} < #{parent}"
        lines.concat(body.map { |line| "#{indent}  #{line.rstrip}" })
        lines << "#{indent}end"
        modules.length.times.reverse_each { |index| lines << "#{'  ' * index}end" }
        lines.join("\n") + "\n"
      end
    end
  end
end
