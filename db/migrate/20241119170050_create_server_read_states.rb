class CreateServerReadStates < ActiveRecord::Migration[7.2]
  def change
    create_table :server_read_states do |t|
      t.references :user, null: false, foreign_key: true
      t.references :server, null: false, foreign_key: true
      t.datetime :last_read_at
      t.integer :unread_count

      t.timestamps
    end

    add_index :server_read_states, [:user_id, :server_id], unique: true
    change_column_default :server_read_states, :unread_count, 0
    change_column_null :server_read_states, :last_read_at, false
  end
end
