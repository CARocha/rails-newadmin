class CreateHostLogin < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.boolean :active, null: false, default: true
      t.references :organization, null: false, foreign_key: true
    end
    add_index :users, :email_address, unique: true
    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :ip_address
      t.string :user_agent
      t.timestamps
    end
  end
end
