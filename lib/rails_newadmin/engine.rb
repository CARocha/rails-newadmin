# frozen_string_literal: true

require "rails"
require "rails/engine"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "active_job/railtie"
require "action_mailer/railtie"

module RailsNewadmin
  class Engine < ::Rails::Engine
    isolate_namespace RailsNewadmin

    initializer "rails_newadmin.resource_path", before: :set_autoload_paths do |app|
      app.paths.add "app/admin/resources", eager_load: true
    end

    initializer "rails_newadmin.filter_credentials" do |app|
      app.config.filter_parameters += [ :password, :password_confirmation, :token ]
    end

    config.to_prepare do
      RailsNewadmin.configuration.validate!
      Dir[Rails.root.join("app/admin/resources/**/*.rb")].sort.each { |path| require_dependency path }
      RailsNewadmin.registry = RailsNewadmin::Registry.new(RailsNewadmin::Resource.descendants.select { |klass| klass.name && klass.name.safe_constantize.equal?(klass) })
    end

    config.after_initialize do
      RailsNewadmin::RateLimitStore.validate_shared! if Rails.env.production?
    end
  end
end
