class QueueItem < ApplicationRecord
  belongs_to :user
  belongs_to :track

  validates :track_id, uniqueness: { scope: :user_id, message: "is already in your queue" }

  before_create :set_position

  private

  def set_position
    self.position ||= (user.queue_items.maximum(:position) || 0) + 1
  end
end
