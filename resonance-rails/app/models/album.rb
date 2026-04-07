class Album < ApplicationRecord
  belongs_to :artist
  has_many :tracks, dependent: :destroy

  def self.ransackable_attributes(auth_object = nil)
    ["title", "release_year", "id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["artist", "tracks"]
  end
end
