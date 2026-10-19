module RailsNewadmin
  class AuditEvent < ApplicationRecord
    serialize :changed_fields, coder: JSON
    validates :actor_type, :actor_id, :resource_key, :record_id, :action, presence: true

    def self.record!(actor:, resource:, action:, record:, request_id: nil)
      key = resource.respond_to?(:resource_key) ? resource.resource_key : resource.to_s
      fields = resource.respond_to?(:permitted_fields) ? record.saved_changes.keys & resource.permitted_fields.map(&:to_s) : []
      create!(actor_type: actor.class.name, actor_id: actor.id.to_s, resource_key: key,
        record_id: record.id.to_s, action: action.to_s, request_id: request_id, changed_fields: fields)
    end
  end
end
