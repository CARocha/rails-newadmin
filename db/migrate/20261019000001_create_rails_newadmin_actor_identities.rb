class CreateRailsNewadminActorIdentities < ActiveRecord::Migration[8.0]
  def change
    create_table :rails_newadmin_actor_identities do |t|
      t.string :actor_type, null: false
      t.string :actor_id, null: false
      t.boolean :active, null: false, default: false
      t.boolean :staff, null: false, default: false
      t.boolean :superuser, null: false, default: false
      t.string :locale
      t.timestamps
    end
    add_index :rails_newadmin_actor_identities, [ :actor_type, :actor_id ], unique: true, name: "rails_newadmin_actor_key"
    create_table :rails_newadmin_actor_memberships do |t|
      t.references :actor_identity, null: false, foreign_key: { to_table: :rails_newadmin_actor_identities }, index: false
      t.references :group, null: false, foreign_key: { to_table: :rails_newadmin_groups }
    end
    add_index :rails_newadmin_actor_memberships, [ :actor_identity_id, :group_id ], unique: true, name: "rails_newadmin_actor_group"
  end
end
