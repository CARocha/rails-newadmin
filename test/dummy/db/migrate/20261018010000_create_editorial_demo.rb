class CreateEditorialDemo < ActiveRecord::Migration[8.0]
  def change
    create_table(:organizations) { |t| t.string :name, null: false }
    create_table :admin_profiles do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :admin_user, null: false, foreign_key: { to_table: :rails_newadmin_admin_users }
    end
    add_index :admin_profiles, :admin_user_id, unique: true, name: "unique_admin_profile"
    create_table :categories do |t|
      t.string :name, null: false
      t.references :organization, null: false, foreign_key: true
    end
    create_table :articles do |t|
      t.string :title, null: false
      t.text :body
      t.string :status, default: "draft", null: false
      t.string :secret_token
      t.integer :lock_version, default: 0, null: false
      t.references :organization, null: false, foreign_key: true
      t.references :category, foreign_key: true
      t.timestamps
    end
  end
end
