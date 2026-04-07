class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :playlists, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :liked_tracks, through: :likes, source: :track
  has_many :queue_items, -> { order(:position) }, dependent: :destroy
  has_many :queued_tracks, through: :queue_items, source: :track

  def self.ransackable_attributes(auth_object = nil)
    ["email", "id", "created_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["playlists"]
  end
end
