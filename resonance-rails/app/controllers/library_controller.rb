class LibraryController < ApplicationController
  before_action :authenticate_user!

  def index
    @playlists = current_user.playlists.order(created_at: :desc)
    @liked_tracks = current_user.liked_tracks.includes(:album, :artist).order("likes.created_at DESC")
  end
end
