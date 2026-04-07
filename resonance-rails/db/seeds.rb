# Seed Data for Resonance Music Platform

# Artists
artists = [
  { name: "The Midnight", bio: "Synthwave band from Los Angeles.", image_url: "https://picsum.photos/seed/midnight/400/400" },
  { name: "Gunship", bio: "British synthwave band formed in 2014.", image_url: "https://picsum.photos/seed/gunship/400/400" },
  { name: "Timecop1983", bio: "Dutch synthwave musician.", image_url: "https://picsum.photos/seed/timecop/400/400" }
]

created_artists = artists.map { |a| Artist.create!(a) }

# Albums & Tracks
created_artists.each do |artist|
  3.times do |i|
    album = Album.create!(
      title: "#{artist.name} Album #{i + 1}",
      artist: artist,
      release_year: 2020 + i,
      cover_url: "https://picsum.photos/seed/#{artist.name.parameterize}#{i}/400/400"
    )

    5.times do |j|
      Track.create!(
        title: "#{artist.name} - Song #{j + 1}",
        album: album,
        duration_seconds: rand(180..300),
        spotify_id: "track_#{artist.id}_#{album.id}_#{j}"
      )
    end
  end
end

puts "Seeded #{Artist.count} artists, #{Album.count} albums, and #{Track.count} tracks."
