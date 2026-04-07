namespace :db do
  desc "Populate database with 25 world-famous artists and categorize existing Punjabi artists"
  task populate_artists: :environment do
    puts "Purging placeholder tracks..."
    Track.where("title LIKE ?", "Greatest Hit %").destroy_all
    Album.where("title LIKE ?", "% Essentials").destroy_all

    puts "Categorizing artists..."
    punjabi_map = {
      "Sukha" => "Hip-Hop",
      "Karan Aujla" => "Punjabi",
      "Diljit Dosanjh" => "Pop",
      "AP Dhillon" => "Hip-Hop",
      "Sidhu Moose Wala" => "Hip-Hop",
      "Arjan Dhillon" => "Punjabi",
      "Navaan Sandhu" => "Hip-Hop",
      "Tegi Pannu" => "Punjabi",
      "Bhalwaan" => "Hip-Hop",
      "Cheema Y" => "Hip-Hop"
    }

    world_genres = {
      "Taylor Swift" => "Pop",
      "The Weeknd" => "R&B",
      "Drake" => "Hip-Hop",
      "Bad Bunny" => "Latin",
      "Beyoncé" => "R&B",
      "Billie Eilish" => "Pop",
      "SZA" => "R&B",
      "Travis Scott" => "Hip-Hop",
      "Olivia Rodrigo" => "Pop",
      "Kendrick Lamar" => "Hip-Hop",
      "Dua Lipa" => "Pop",
      "Harry Styles" => "Pop",
      "Post Malone" => "Pop",
      "Doja Cat" => "Hip-Hop",
      "Karol G" => "Latin",
      "Peso Pluma" => "Latin",
      "Ed Sheeran" => "Pop",
      "Justin Bieber" => "Pop",
      "Ariana Grande" => "Pop",
      "Lana Del Rey" => "Indie",
      "Future" => "Hip-Hop",
      "Metro Boomin" => "Hip-Hop",
      "Rihanna" => "R&B",
      "Tyler, The Creator" => "Hip-Hop",
      "Fred again.." => "Electronic"
    }

    puts "\nPerforming high-fidelity Bulk Import via Deezer..."
    world_genres.each_key do |name|
      DeezerImporter.import_artist(name)
    end

    puts "\nApplying primary genres..."
    all_mappings = punjabi_map.merge(world_genres)
    all_mappings.each do |name, genre|
      artist = Artist.find_by("name ILIKE ?", name)
      if artist
        artist.update(primary_genre: genre)
      end
    end

    puts "\nFinalizing Sync with ML service..."
    Rake::Task["ml:sync_tracks"].invoke
    puts "Sync complete."
  end
end
