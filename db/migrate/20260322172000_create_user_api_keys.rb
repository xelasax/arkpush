# frozen_string_literal: true

class CreateUserApiKeys < ActiveRecord::Migration[7.1]
  def change
    create_table :user_api_keys do |t|
      t.integer :user_id
      t.string :name
      t.string :key
      t.datetime :last_used_at
      t.timestamps
    end

    add_index :user_api_keys, :user_id
    add_index :user_api_keys, :key, unique: true
  end
end
