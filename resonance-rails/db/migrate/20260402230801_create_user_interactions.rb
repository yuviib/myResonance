class CreateUserInteractions < ActiveRecord::Migration[8.1]
  def change
    create_table :user_interactions do |t|
      t.string :user_identifier
      t.references :track, null: false, foreign_key: true
      t.integer :play_count

      t.timestamps
    end
  end
end
