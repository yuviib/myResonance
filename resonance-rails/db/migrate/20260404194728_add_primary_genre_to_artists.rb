class AddPrimaryGenreToArtists < ActiveRecord::Migration[8.1]
  def change
    add_column :artists, :primary_genre, :string
  end
end
