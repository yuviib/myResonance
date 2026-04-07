class CreateArtists < ActiveRecord::Migration[8.1]
  def change
    create_table :artists do |t|
      t.string :name
      t.text :bio
      t.string :image_url

      t.timestamps
    end
  end
end
