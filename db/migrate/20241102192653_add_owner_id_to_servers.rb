class AddOwnerIdToServers < ActiveRecord::Migration[7.2]
  def change
    add_reference :servers, :owner, null: false, foreign_key: { to_table: :users }
  end
end
