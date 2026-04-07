class CreateAlbums < ActiveRecord::Migration[8.1]
  def change
    create_table :albums do |t|
      t.string :title
      t.references :artist, null: false, foreign_key: true
      t.integer :release_year
      t.string :cover_url

      t.timestamps
    end
  end
end
