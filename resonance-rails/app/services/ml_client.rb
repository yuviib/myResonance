class MlClient
  include HTTParty
  base_uri "http://localhost:8000"

  def self.sync_all_tracks
    new.sync_all_tracks
  end

  def self.fetch_recommendations(user, limit: 10)
    new.fetch_recommendations(user, limit: limit)
  end

  def sync_all_tracks
    tracks_payload = Track.includes(:artist).all.map do |track|
      {
        id: track.id,
        title: track.title,
        artist: track.artist&.name || "Unknown",
        genre: track.artist&.primary_genre&.downcase || "pop"
      }
    end

    response = self.class.post("/api/v1/sync",
      body: tracks_payload.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    if response.success?
      Rails.logger.info "Successfully synced #{tracks_payload.size} tracks to ML Engine."
      true
    else
      Rails.logger.error "ML Sync Failed: #{response.code} - #{response.body}"
      false
    end
  rescue StandardError => e
    Rails.logger.error "ML Sync Connection Failed: #{e.message}"
    false
  end

  def fetch_recommendations(user, limit: 10)
    history = build_history(user)
    
    response = self.class.post("/api/v1/recommendations", 
      body: { 
        user_id: user&.id,
        history: history,
        limit: limit 
      }.to_json,
      headers: { 'Content-Type' => 'application/json' },
      timeout: 2 # Fast fail for better UX
    )

    if response.success?
      JSON.parse(response.body)
    else
      Rails.logger.error "ML Service Error: #{response.code} - #{response.body}"
      nil
    end
  rescue StandardError => e
    Rails.logger.error "ML Service Connection Failed: #{e.message}"
    nil
  end

  private

  def build_history(user)
    return [] unless user

    # Combine Likes and Recent Interactions
    # Action mapping: Like -> 'like', Interaction -> 'play'
    
    # 1. Recent Likes
    likes = user.likes.includes(track: :album).order(created_at: :desc).limit(10).map do |like|
      {
        track_id: like.track_id,
        genre: detect_genre(like.track),
        action: 'like',
        timestamp: like.created_at
      }
    end

    # 2. Recent Interactions (Plays & Skips)
    interactions = UserInteraction.where(user_identifier: user.email)
                                  .includes(track: :artist)
                                  .order(updated_at: :desc)
                                  .limit(10).map do |interaction|
      
      # Determine action based on completion percentage (The Signal)
      pct = interaction.completion_percentage || 1.0
      action = (pct < 0.2) ? 'skip' : 'play'

      {
        track_id: interaction.track_id,
        genre: detect_genre(interaction.track),
        action: action,
        completion_percentage: pct,
        timestamp: interaction.updated_at
      }
    end

    # 3. Time-Series Alignment
    # SASRec expects a chronological sequence: Oldest -> Newest.
    # We combine them, sort by timestamp ascending, so the LAST item is the absolute latest.
    history = (likes + interactions).sort_by { |h| h[:timestamp] }
    
    # Deduplicate keeping the NEWEST occurrence (which is at the end of the array)
    history = history.reverse.uniq { |h| h[:track_id] }.reverse

    history.last(15).map { |h| h.except(:timestamp) }
  end

  def detect_genre(track)
    # Use the new structured primary_genre field from the Artist model
    track.artist&.primary_genre&.downcase || "pop"
  end
end
