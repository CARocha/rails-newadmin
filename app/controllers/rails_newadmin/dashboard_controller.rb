module RailsNewadmin
  class DashboardController < ApplicationController
    def index
      @resources = RailsNewadmin.registry.select { |resource| Access.new(current_actor, resource).allowed?(:view) }
    end
  end
end
