class Artist < ApplicationRecord
  has_many :albums, dependent: :destroy
  has_many :tracks, through: :albums

  def self.ransackable_attributes(auth_object = nil)
    ["name", "bio", "id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["albums", "tracks"]
  end
end
