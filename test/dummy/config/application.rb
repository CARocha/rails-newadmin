require_relative "boot"
require "rails"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "active_job/railtie"
require "action_mailer/railtie"
require "propshaft"
require "rails/test_unit/railtie"
Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    config.load_defaults 8.0
    config.eager_load = false
    config.enable_reloading = Rails.env.development?
    config.secret_key_base = Rails.env.production? ? ENV.fetch("SECRET_KEY_BASE") : ENV.fetch("SECRET_KEY_BASE", "test-only-" * 16)
    config.hosts = ["www.example.com", "127.0.0.1", "localhost"]
    config.action_mailer.delivery_method = :test
    config.action_mailer.default_url_options = { host: "www.example.com" }
    config.action_mailer.default_options = { from: "no-reply@example.test" }
    config.active_job.queue_adapter = :inline
    config.active_support.deprecation = :raise
    config.action_dispatch.show_exceptions = :rescuable
    config.logger = ActiveSupport::Logger.new(File::NULL)
    config.cache_store = :memory_store
  end
end
