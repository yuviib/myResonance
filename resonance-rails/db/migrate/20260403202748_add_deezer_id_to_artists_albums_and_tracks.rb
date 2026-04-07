class AddDeezerIdToArtistsAlbumsAndTracks < ActiveRecord::Migration[8.1]
  def change
    add_column :artists, :deezer_id, :string
    add_index :artists, :deezer_id, unique: true

    add_column :albums, :deezer_id, :string
    add_index :albums, :deezer_id, unique: true

    add_column :tracks, :deezer_id, :string
    add_index :tracks, :deezer_id, unique: true
  end
end
