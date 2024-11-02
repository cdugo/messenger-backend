class CreateServerMembers < ActiveRecord::Migration[7.2]
  def change
    create_table :server_members do |t|
      t.belongs_to :user, null: false, foreign_key: true
      t.belongs_to :server, null: false, foreign_key: true

      t.timestamps
    end
    
    add_index :server_members, [:user_id, :server_id], unique: true
  end
end 