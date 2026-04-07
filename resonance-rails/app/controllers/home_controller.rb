class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    # Trending Now: Top 10 tracks by interaction count in the last 7 days
    @recent_tracks = Track.includes(:album, :artist)
                          .joins(:user_interactions)
                          .where(user_interactions: { created_at: 7.days.ago..Time.current })
                          .group(:id)
                          .order("count(user_interactions.id) DESC")
                          .limit(10)

    # Fallback: Complemented with newest tracks if interaction data is sparse
    if @recent_tracks.length < 10
      newest = Track.includes(:album, :artist).order(created_at: :desc).limit(10)
      @recent_tracks = (@recent_tracks.to_a + newest.to_a).uniq.first(10)
    end

    @artists = Artist.all.limit(6)
    @albums  = Album.includes(:artist).order("RANDOM()").limit(5)
    
    # Recommendations now loaded asynchronously via turbo frame
    # See RecommendationsController#index
  end
end
