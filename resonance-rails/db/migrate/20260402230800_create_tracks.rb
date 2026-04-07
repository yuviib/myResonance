class CreateTracks < ActiveRecord::Migration[8.1]
  def change
    create_table :tracks do |t|
      t.string :title
      t.references :album, null: false, foreign_key: true
      t.integer :duration_seconds
      t.string :spotify_id

      t.timestamps
    end
  end
end
