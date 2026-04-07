class AddPrecisionToUserInteractions < ActiveRecord::Migration[8.1]
  def change
    add_column :user_interactions, :listen_duration, :integer
    add_column :user_interactions, :completion_percentage, :float
  end
end
