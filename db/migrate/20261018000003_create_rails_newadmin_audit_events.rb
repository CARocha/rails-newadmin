class CreateRailsNewadminAuditEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :rails_newadmin_audit_events do |t|
      t.string :actor_type, null: false
      t.string :actor_id, null: false
      t.string :resource_key, null: false
      t.string :record_id, null: false
      t.string :action, null: false
      t.string :request_id
      t.text :changed_fields, null: false, default: "[]"
      t.datetime :created_at, null: false
    end
    add_index :rails_newadmin_audit_events, [ :resource_key, :record_id, :created_at ], name: "rails_newadmin_audit_resource"
  end
end
