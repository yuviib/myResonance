class UpdateUserInteractionsForEventLog < ActiveRecord::Migration[8.1]
  def change
    add_column :user_interactions, :action, :string
    add_column :user_interactions, :session_id, :string
  end
end
