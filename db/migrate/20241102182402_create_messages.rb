class CreateMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :messages do |t|
      t.text :content
      t.belongs_to :user, null: false, foreign_key: true
      t.belongs_to :server, null: false, foreign_key: true
      t.belongs_to :parent_message, null: true, foreign_key: { to_table: :messages }

      t.timestamps
    end
  end
end
