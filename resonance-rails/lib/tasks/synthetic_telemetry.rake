namespace :ml do
  desc "Generate dense synthetic telemetry to train the ML pipeline"
  task generate_synthetic: :environment do
    puts "Booting synthetic data generator..."

    if Track.count < 10
      puts "Error: Not enough tracks in the database to generate meaningul telemetry."
      exit
    end

    puts "Structuring track catalog..."
    # Group tracks by the primary genre of their artist
    tracks_by_genre = Track.joins(album: :artist).group_by { |t| t.album.artist.primary_genre || "Unknown" }
    genres = tracks_by_genre.keys
    
    if genres.empty?
      puts "Error: No genres found in artist data!"
      exit
    end

    num_users = 50
    sessions_per_user = 3
    interactions_per_session = 15

    puts "Generating telemetry for #{num_users} users across #{genres.size} genres..."
    
    # Pre-fetch track arrays to speed up sampling
    track_pool = tracks_by_genre.transform_values { |tracks| tracks.to_a }

    # Disable ActiveRecord transaction overhead for massive inserts, but we'll use raw inserts if needed
    # For 50 * 3 * 15 = 2250 records, active record create! is fast enough.
    
    interactions_created = 0

    num_users.times do |i|
      user_identifier = "synth_user_#{i}@resonance.ai"
      fav_genre = genres.sample
      other_genres = genres - [fav_genre]
      other_genres = [fav_genre] if other_genres.empty?
      
      sessions_per_user.times do |s|
        session_id = "batch_#{Time.now.to_i}_u#{i}_s#{s}"
        
        interactions_per_session.times do |pos_obj|
          # 80% chance of pulling from their favorite genre
          if rand < 0.8 && track_pool[fav_genre].present?
            track = track_pool[fav_genre].sample
            pct = rand(0.5..1.0) # Play or complete
            action = "play"
          else
            # Random genre exploration (mostly skips)
            rand_genre = other_genres.sample
            track = track_pool[rand_genre].sample
            pct = rand(0.0..0.15) # Hard skip
            action = "skip"
          end
          
          next unless track
          
          UserInteraction.create!(
            user_identifier: user_identifier,
            session_id: session_id,
            track_id: track.id,
            action: action, 
            completion_percentage: pct,
            created_at: Time.now - rand(1..30).days + (pos_obj * 3).minutes
          )
          
          interactions_created += 1
        end
      end
      print "."
    end
    
    puts "\nSuccessfully generated #{interactions_created} dense synthetic interactions!"
    puts "Total Interactions in DB: #{UserInteraction.count}"
    puts "You can now run 'rails runner \"NeuralSyncJob.perform_now\"' to train the BPR model."
  end
end
