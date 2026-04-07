class LikesController < ApplicationController
  before_action :authenticate_user!

  def create
    track = Track.find(params[:track_id])
    current_user.likes.find_or_create_by(track: track)
    redirect_back fallback_location: dashboard_path
  end

  def destroy
    track = Track.find(params[:track_id])
    like = current_user.likes.find_by(track: track)
    like&.destroy
    redirect_back fallback_location: dashboard_path
  end
end
