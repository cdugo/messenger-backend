class AddAuthenticationToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :password_digest, :string
    add_index :users, :username, unique: true
    remove_column :users, :password, :string
  end
end
