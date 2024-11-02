class AddDefaultValueToActiveUser < ActiveRecord::Migration[7.2]
  def change
    change_column_default :users, :is_active, false
  end
end
