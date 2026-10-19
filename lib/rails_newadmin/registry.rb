# frozen_string_literal: true

module RailsNewadmin
  class Registry
    include Enumerable

    def initialize(resources = [])
      @resources = {}
      resources.each do |resource|
        resource.validate!
        key = resource.resource_key
        raise ConfigurationError, "duplicate resource: #{key}" if @resources.key?(key)
        @resources[key] = resource
      end
      @resources.freeze
    end

    def fetch(key)
      @resources.fetch(key.to_s)
    end

    def each(&block)
      @resources.values.each(&block)
    end
  end
end
