module Tracks
  class LikesController < ApplicationController
    before_action :authenticate_user!

    def create
      @track = Track.find(params[:track_id])
      current_user.likes.find_or_create_by(track: @track)
      
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(helpers.dom_id(@track, :like_button), partial: "shared/like_button", locals: { track: @track }) }
        format.html { redirect_back fallback_location: dashboard_path }
      end
    end

    def destroy
      @track = Track.find(params[:track_id])
      like = current_user.likes.find_by(track: @track)
      like&.destroy
      
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(helpers.dom_id(@track, :like_button), partial: "shared/like_button", locals: { track: @track }) }
        format.html { redirect_back fallback_location: dashboard_path }
      end
    end
  end
end
