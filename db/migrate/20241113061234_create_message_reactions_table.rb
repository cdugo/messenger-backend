class CreateMessageReactionsTable < ActiveRecord::Migration[7.2]
  def change
    create_table :message_reactions do |t|
      t.references :message, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :emoji

      t.timestamps
    end
  end
end
