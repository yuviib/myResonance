namespace :neural_sync do
  desc "Export immutable telemetry and trigger SASRec incremental fine-tuning"
  task fine_tune: :environment do
    require 'csv'
    require 'net/http'
    require 'uri'

    export_path = File.expand_path("../../../../resonance-ml/data/interactions.csv", __FILE__)
    puts "--- NEURAL TELEMETRY EXPORT [Phase 10] ---"
    puts "Target: #{export_path}"

    # 1. Export UserInteractions to CSV
    interactions = UserInteraction.all
    if interactions.empty?
      puts "No interactions found. Aborting fine-tuning."
      next
    end

    CSV.open(export_path, "wb") do |csv|
      csv << ["user_identifier", "session_id", "track_id", "action", "completion_percentage", "created_at"]
      interactions.find_each do |interaction|
        csv << [
          interaction.user_identifier,
          interaction.session_id,
          interaction.track_id,
          interaction.action,
          interaction.completion_percentage,
          interaction.created_at
        ]
      end
    end
    puts "Exported #{interactions.count} sequential events."

    # 2. Trigger Python Incremental Epoch
    puts "Triggering Neural Pulse Fine-Tuning..."
    uri = URI.parse("http://localhost:8000/api/v1/train")
    begin
      response = Net::HTTP.post_form(uri, "data_path" => "data/interactions.csv")
      if response.code == "200"
        result = JSON.parse(response.body)
        puts "Neural Pulse Success: #{result['status']}"
        puts "Engine State: #{result['engine']}"
      else
        puts "Neural Pulse Failed: HTTP #{response.code}"
      end
    rescue StandardError => e
      puts "Neural Pulse Trigger Error: #{e.message}"
    end

    puts "--- EXPORT COMPLETE ---"
  end

  desc "Synchronize all tracks with ML Engine"
  task sync_all_tracks: :environment do
    require 'net/http'
    require 'uri'
    require 'json'

    tracks = Track.includes(album: :artist).all.map do |t|
      {
        id: t.id,
        title: t.title,
        artist: t.album.artist.name,
        genre: t.album.artist.primary_genre || "unknown"
      }
    end

    uri = URI("http://localhost:8000/api/v1/sync")
    puts "--- NEURAL TRACK SYNC ---"
    puts "Syncing #{tracks.size} tracks to ML engine at #{uri}..."

    begin
      res = Net::HTTP.post(uri, tracks.to_json, 'Content-Type' => 'application/json')
      puts "Sync Result: #{res.body}"
    rescue => e
      puts "Sync Failed: #{e.message}"
    end
  end
end
