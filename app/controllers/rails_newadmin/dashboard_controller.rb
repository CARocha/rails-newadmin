module RailsNewadmin
  class DashboardController < ApplicationController
    def index
      @resources = RailsNewadmin.registry.select { |resource| resource_access(resource).allowed?(:view) }
    end
  end
end
