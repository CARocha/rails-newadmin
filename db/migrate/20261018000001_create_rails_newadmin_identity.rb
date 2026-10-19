class CreateRailsNewadminIdentity < ActiveRecord::Migration[8.0]
  def change
    create_table :rails_newadmin_admin_users do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.boolean :active, null: false, default: true
      t.boolean :staff, null: false, default: false
      t.boolean :superuser, null: false, default: false
      t.string :locale
      t.timestamps
    end
    add_index :rails_newadmin_admin_users, :email_address, unique: true
    create_table :rails_newadmin_admin_sessions do |t|
      t.references :admin_user, null: false, foreign_key: { to_table: :rails_newadmin_admin_users }
      t.string :token_digest, null: false
      t.datetime :last_seen_at, null: false
      t.datetime :expires_at, null: false
      t.timestamps
    end
    add_index :rails_newadmin_admin_sessions, :token_digest, unique: true
  end
end
