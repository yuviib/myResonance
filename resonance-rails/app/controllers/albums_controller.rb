class AlbumsController < ApplicationController
  before_action :authenticate_user!

  def show
    @album = Album.find(params[:id])
    @tracks = @album.tracks.includes(:artist).order(:created_at)
  end
end
