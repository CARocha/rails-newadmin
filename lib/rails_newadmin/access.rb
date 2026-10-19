# frozen_string_literal: true
module RailsNewadmin
  class Access
    attr_reader :actor, :resource, :policy

    def initialize(actor, resource)
      @actor, @resource = actor, resource
      @policy = (resource.policy_name || "RailsNewadmin::Policy").constantize.new(resource)
    end

    def granted?(action)
      actor&.administrative? && (actor.superuser? || actor.has_permission?(resource.resource_key, action.to_s))
    end

    def allowed?(action, record = nil)
      granted?(action) && policy.allowed?(actor: actor, action: action.to_sym, record: record)
    end

    def scope
      relation = policy.scope(actor: actor, relation: resource.model_class.all)
      unless relation.is_a?(ActiveRecord::Relation) && relation.klass == resource.model_class
        raise ConfigurationError, "policy scope must return the resource's ActiveRecord relation"
      end
      relation
    end

    def permitted_attributes(action, record)
      fields = policy.permitted_attributes(actor: actor, action: action, record: record)
      resource.permitted_fields & Array(fields).map(&:to_sym)
    end
  end
end
