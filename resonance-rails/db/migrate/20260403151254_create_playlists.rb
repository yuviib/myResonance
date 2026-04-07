class CreatePlaylists < ActiveRecord::Migration[8.1]
  def change
    create_table :playlists do |t|
      t.belongs_to :user, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.string :image_url

      t.timestamps
    end
  end
end
