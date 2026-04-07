class Track < ApplicationRecord
  belongs_to :album
  has_one :artist, through: :album
  has_many :playlist_tracks
  has_many :playlists, through: :playlist_tracks
  has_many :likes, dependent: :destroy
  has_many :user_interactions, dependent: :destroy
  has_many :queue_items, dependent: :destroy

  def self.ransackable_attributes(auth_object = nil)
    ["title", "spotify_id", "id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["album", "artist", "playlists"]
  end
end
