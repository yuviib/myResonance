class Playlist < ApplicationRecord
  belongs_to :user
  has_many :playlist_tracks, dependent: :destroy
  has_many :tracks, through: :playlist_tracks

  validates :title, presence: true

  def self.ransackable_attributes(auth_object = nil)
    ["title", "description", "id", "created_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["user", "tracks"]
  end
end
