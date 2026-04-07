class ArtistsController < ApplicationController
  before_action :authenticate_user!

  def index
    @artists = Artist.includes(:albums).order(:name)
  end

  def show
    @artist = Artist.find(params[:id])
    @tracks = @artist.tracks.includes(:album).order(created_at: :desc)
    @albums = @artist.albums.order(release_year: :desc)
  end
end
