class AddPreviewUrlToTracks < ActiveRecord::Migration[8.1]
  def change
    add_column :tracks, :preview_url, :string
  end
end
