namespace :deezer do
  desc "Import an artist and their top 25 tracks from Deezer API"
  task :import, [:artist_name] => :environment do |_, args|
    artist_name = args[:artist_name]
    if artist_name.blank?
      puts "Usage: bin/rails \"deezer:import[Artist Name]\""
      next
    end

    puts "Searching for '#{artist_name}' on Deezer..."
    begin
      artist = DeezerImporter.import_artist(artist_name)
      if artist
        puts "Successfully imported #{artist.name} and their tracks."
      else
        puts "Import failed for #{artist_name}."
      end
    rescue StandardError => e
      puts "An error occurred: #{e.message}"
    end
  end
end
