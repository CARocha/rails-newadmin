# frozen_string_literal: true

module RailsNewadmin
  class ConfigurationError < StandardError; end
  class AccessDenied < StandardError; end

  class Configuration
    attr_accessor :site_title, :default_mode, :default_locale, :available_locales,
      :session_lifetime, :session_idle_timeout, :authentication, :authentication_adapter,
      :rate_limit_store, :dashboard_provider

    def initialize
      @site_title = "NewAdmin"
      @default_mode = :auto
      @default_locale = :es
      @available_locales = [ :es, :en ]
      @session_lifetime = 12.hours
      @session_idle_timeout = 30.minutes
      @authentication = :builtin
    end

    def validate!
      raise ConfigurationError, "default_mode must be light, dark or auto" unless %i[light dark auto].include?(default_mode)
      unless available_locales.is_a?(Array) && available_locales.any? && (available_locales - %i[es en]).empty? && available_locales.include?(default_locale)
        raise ConfigurationError, "available_locales must contain default_locale and only es/en"
      end
      raise ConfigurationError, "session timeouts must be positive" unless [ session_lifetime, session_idle_timeout ].all? { |value| value.is_a?(Numeric) && value.positive? }
      raise ConfigurationError, "site_title must be non-empty text" unless site_title.is_a?(String) && site_title.present?
      raise ConfigurationError, "This alpha supports builtin authentication; host adapters are a later integration" unless authentication == :builtin
      if dashboard_provider && (!dashboard_provider.is_a?(String) || !/\A[A-Z]\w*(?:::[A-Z]\w*)*\z/.match?(dashboard_provider))
        raise ConfigurationError, "dashboard_provider must be a class-name string"
      end
      self
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
      configuration.validate!
    end

    def registry
      @registry ||= Registry.new
    end

    attr_writer :registry
  end
end
