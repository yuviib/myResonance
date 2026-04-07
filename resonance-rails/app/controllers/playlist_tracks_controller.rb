class PlaylistTracksController < ApplicationController
  before_action :authenticate_user!

  def create
    playlist = current_user.playlists.find(params[:playlist_id])
    @track = Track.find(params[:track_id])

    unless playlist.tracks.include?(@track)
      playlist.playlist_tracks.create!(track: @track)
      flash.now[:notice] = "\"#{@track.title}\" added to #{playlist.title}."
    else
      flash.now[:alert] = "That song is already in #{playlist.title}."
    end

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace(helpers.dom_id(@track, :add_to_playlist), partial: "shared/add_to_playlist", locals: { track: @track }) }
      format.html { redirect_back fallback_location: dashboard_path }
    end
  end

  def destroy
    playlist_track = PlaylistTrack.find(params[:id])
    playlist = playlist_track.playlist

    if playlist.user == current_user
      playlist_track.destroy
      flash[:notice] = "Track removed from playlist."
    else
      flash[:alert] = "Not authorized."
    end

    redirect_back fallback_location: playlist_path(playlist)
  end
end
