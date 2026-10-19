# frozen_string_literal: true
module RailsNewadmin
  class RateLimitStore
    def self.backend = RailsNewadmin.configuration.rate_limit_store || Rails.cache

    def self.validate_shared!(store = backend)
      local_classes = [ActiveSupport::Cache::MemoryStore, ActiveSupport::Cache::NullStore, ActiveSupport::Cache::FileStore]
      if !store.respond_to?(:increment) || local_classes.any? { |klass| store.is_a?(klass) }
        raise ConfigurationError, "Configure a shared atomic rate_limit_store (for example RedisCacheStore) before production."
      end
      store
    end

    def increment(key, amount, **options)
      store = self.class.backend
      self.class.validate_shared!(store) if Rails.env.production?
      value = store.increment(key, amount, **options)
      raise ConfigurationError, "rate_limit_store failed to increment; authentication is closed" unless value.is_a?(Integer)
      value
    end
  end
end
