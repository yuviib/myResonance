class CreateQueueItems < ActiveRecord::Migration[8.1]
  def change
    create_table :queue_items do |t|
      t.references :user, null: false, foreign_key: true
      t.references :track, null: false, foreign_key: true
      t.integer :position

      t.timestamps
    end
    add_index :queue_items, [:user_id, :track_id], unique: true
  end
end
