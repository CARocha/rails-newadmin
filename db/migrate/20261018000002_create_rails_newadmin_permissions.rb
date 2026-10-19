class CreateRailsNewadminPermissions < ActiveRecord::Migration[8.0]
  def change
    create_table :rails_newadmin_groups do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :rails_newadmin_groups, :name, unique: true
    create_table :rails_newadmin_memberships do |t|
      t.references :admin_user, null: false, foreign_key: { to_table: :rails_newadmin_admin_users }
      t.references :group, null: false, foreign_key: { to_table: :rails_newadmin_groups }
    end
    add_index :rails_newadmin_memberships, [ :admin_user_id, :group_id ], unique: true
    create_table :rails_newadmin_permissions do |t|
      t.string :resource_key, null: false
      t.string :action, null: false
      t.boolean :active, default: true, null: false
    end
    add_index :rails_newadmin_permissions, [ :resource_key, :action ], unique: true
    create_table :rails_newadmin_group_permissions do |t|
      t.references :group, null: false, foreign_key: { to_table: :rails_newadmin_groups }
      t.references :permission, null: false, foreign_key: { to_table: :rails_newadmin_permissions }
    end
    add_index :rails_newadmin_group_permissions, [ :group_id, :permission_id ], unique: true
  end
end
