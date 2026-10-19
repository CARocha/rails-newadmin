# frozen_string_literal: true

module RailsNewadmin
  class DashboardProvider
    class_attribute :required_resources, instance_accessor: false, default: [].freeze

    def self.requires(*keys)
      self.required_resources = keys.map(&:to_s).freeze
    end

    def initialize(actor:)
      @actor = actor
    end

    def visible?
      required_resources.any? && required_resources.all? { |key| access(key).allowed?(:view) }
    end

    def scope(key)
      raise ConfigurationError, "dashboard resource must be declared with requires" unless required_resources.include?(key.to_s)
      authorization = access(key)
      raise AccessDenied unless authorization.allowed?(:view)
      authorization.scope
    end

    def call
      { metrics: required_resources.map { |key| { label: key, value: scope(key).count } }, charts: [] }
    end

    def data
      value = call
      raise ConfigurationError, "dashboard must return a Hash" unless value.is_a?(Hash)
      metrics, charts = Array(value[:metrics]), Array(value[:charts])
      raise ConfigurationError, "dashboard exceeds component limits" if metrics.size > 12 || charts.size > 8
      metrics.each do |metric|
        unless metric.is_a?(Hash) && metric[:label].is_a?(String) && metric[:value].is_a?(Numeric) && metric[:value].finite?
          raise ConfigurationError, "metric requires a label and finite numeric value"
        end
      end
      charts.each do |chart|
        valid = chart.is_a?(Hash) && /\A[a-z][a-z0-9_-]*\z/.match?(chart[:id].to_s) && chart[:title].is_a?(String)
        valid &&= %w[bar line].include?(chart[:type].to_s) && chart[:columns].is_a?(Array) && chart[:columns].size == 2 && chart[:columns].all? { |column| column.is_a?(String) }
        valid &&= chart[:rows].is_a?(Array) && chart[:rows].size <= 1000
        valid &&= chart[:rows].all? { |row| row.is_a?(Array) && row.size == 2 && row[0].is_a?(String) && row[1].is_a?(Numeric) && row[1].finite? }
        raise ConfigurationError, "chart requires a safe id, bar/line type and two-column data" unless valid
      end
      { metrics: metrics, charts: charts.map { |chart| chart.slice(:id, :title, :type, :columns, :rows) } }
    end

    private

    def required_resources = self.class.required_resources

    def access(key)
      Access.new(@actor, RailsNewadmin.registry.fetch(key))
    end
  end
end
