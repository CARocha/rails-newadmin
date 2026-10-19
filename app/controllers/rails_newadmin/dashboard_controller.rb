module RailsNewadmin
  class DashboardController < ApplicationController
    def index
      @resources = RailsNewadmin.registry.select { |resource| resource_access(resource).allowed?(:view) }
      @metrics = @resources.map do |resource|
        { key: resource.resource_key, label: resource.model_class.model_name.human(count: 2), value: resource_access(resource).scope.count }
      end
      @dashboard_data = { metrics: [], charts: [] }
      if admin_config.dashboard_provider
        klass = admin_config.dashboard_provider.constantize
        raise ConfigurationError, "dashboard_provider must inherit DashboardProvider" unless klass < DashboardProvider
        provider = klass.new(actor: current_actor)
        @dashboard_data = provider.data if provider.visible?
      end
    end
  end
end
