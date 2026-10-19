# frozen_string_literal: true
module RailsNewadmin
  class Policy
    attr_reader :resource

    def initialize(resource)
      @resource = resource
    end

    def allowed?(actor:, action:, record: nil) = false
    def scope(actor:, relation:) = relation.none
    def permitted_attributes(actor:, action:, record: nil) = []
  end
end
