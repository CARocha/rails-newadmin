# frozen_string_literal: true
require "active_support/core_ext/class/attribute"

module RailsNewadmin
  class Resource
    class_attribute :model_name, :resource_key, :policy_name, instance_accessor: false
    class_attribute :column_names, :field_names, :permitted_fields, :search_fields, :filter_fields,
      :preload_names, instance_accessor: false, default: [].freeze

    class << self
      def model(name)
        self.model_name = constant_name!(name)
      end

      def model_class
        model_name.constantize
      end

      def key(value)
        raise ConfigurationError, "invalid resource key" unless value.is_a?(String) && /\A[a-z][a-z0-9_]*\z/.match?(value)
        self.resource_key = value.dup.freeze
      end

      def policy(name)
        self.policy_name = constant_name!(name)
      end

      { columns: :column_names, fields: :field_names, permit: :permitted_fields,
        search: :search_fields, filters: :filter_fields, includes: :preload_names }.each do |dsl, attribute|
        define_method(dsl) { |*names| public_send("#{attribute}=", field_list!(names)) }
      end

      def validate!
        raise ConfigurationError, "resource requires model and key" unless model_name && resource_key
        self
      end

      private

      def constant_name!(name)
        raise ConfigurationError, "expected a constant name string" unless name.is_a?(String) && /\A[A-Z]\w*(?:::[A-Z]\w*)*\z/.match?(name)
        name.dup.freeze
      end

      def field_list!(names)
        raise ConfigurationError, "fields must be simple attribute names" unless names.all? { |name| /\A[a-z][a-z0-9_]*\z/.match?(name.to_s) }
        names.map(&:to_sym).uniq.freeze
      end
    end
  end
end
