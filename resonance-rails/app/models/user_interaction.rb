class UserInteraction < ApplicationRecord
  belongs_to :track

  validates :action, presence: true
  validates :session_id, presence: true
  validates :user_identifier, presence: true
end
