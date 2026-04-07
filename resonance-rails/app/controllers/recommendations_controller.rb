class RecommendationsController < ApplicationController
  before_action :authenticate_user!

  def index
    ai_response = MlClient.fetch_recommendations(current_user)
    
    # Extract visualization context
    @engine_name = ai_response&.dig("engine") || "Standard-Heuristic"
    @discovery_message = ai_response&.dig("context_message") || "Handpicked just for you."
    
    # Fetch actual input sequence for visualization
    # This reflects the exact tracks the AI just analyzed
    interactions = UserInteraction.where(user_identifier: current_user.email)
                                  .order(updated_at: :desc)
                                  .limit(5)
    @input_sequence = interactions.map(&:track).compact
    
    if ai_response && ai_response["recommended_track_ids"].any?
      Rails.logger.info "AI Engine [#{@engine_name}]: Delivering high-fidelity discovery for User##{current_user.id}"
      @featured_tracks = Track.where(id: ai_response["recommended_track_ids"]).includes(:album, :artist)
    else
      Rails.logger.warn "AI Engine: Fallback triggered for User##{current_user.id}"
      @featured_tracks = Track.includes(:album, :artist).order("RANDOM()").limit(5)
    end

    render layout: false
  end
end
