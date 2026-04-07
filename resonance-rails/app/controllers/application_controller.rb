class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :load_sidebar_data, if: :user_signed_in?

  private

  def load_sidebar_data
    @sidebar_playlists = current_user.playlists.order(created_at: :desc).limit(8)
  end
end
