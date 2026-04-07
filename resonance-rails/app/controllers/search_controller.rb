class SearchController < ApplicationController
  before_action :authenticate_user!

  def index
    @query = params[:q]
    @genre = params[:genre]

    if @query.present?
      @tracks = Track.where("title ILIKE ?", "%#{@query}%").limit(20)
      @artists = Artist.where("name ILIKE ?", "%#{@query}%").limit(10)
      @albums = Album.where("title ILIKE ?", "%#{@query}%").limit(10)
    elsif @genre.present?
      @artists = Artist.where("primary_genre ILIKE ?", @genre).limit(20)
      @tracks = Track.joins(:artist).where("artists.primary_genre ILIKE ?", @genre).limit(20)
      @albums = Album.joins(:artist).where("artists.primary_genre ILIKE ?", @genre).limit(10)
    else
      @tracks = Track.none
      @artists = Artist.none
      @albums = Album.none
    end
  end
end
