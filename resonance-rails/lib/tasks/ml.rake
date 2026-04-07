namespace :ml do
  desc "Sync all tracks to the ML Engine"
  task sync_tracks: :environment do
    puts "Pushing tracks to Resonance ML Service..."
    
    tracks = Track.includes(album: :artist).all
    payload = tracks.map do |track|
      {
        id: track.id,
        title: track.title,
        artist: track.artist&.name || "Unknown",
        genre: detect_genre(track)
      }
    end

    begin
      response = HTTParty.post("http://localhost:8000/api/v1/sync",
        body: payload.to_json,
        headers: { 'Content-Type' => 'application/json' },
        timeout: 10
      )

      if response.success?
        puts "Successfully synced #{tracks.count} tracks to ML service."
      else
        puts "Sync failed: #{response.code} - #{response.body}"
      end
    rescue StandardError => e
      puts "Error connecting to ML service: #{e.message}"
      puts "Make sure the FastAPI service is running on port 8000."
    end
  end

  def detect_genre(track)
    name = track.artist&.name&.downcase || ""
    if name.include?("karj") || name.include?("punj") || name.include?("aujla")
      "punjabi"
    elsif name.include?("pop")
      "pop"
    else
      "pop"
    end
  end
end
