require 'net/http'
require 'json'

# Service responsible for synchronizing local music metadata with the Deezer catalog.
# Rationale: Deezer serves as our primary metadata truth; local records are refreshed 
# periodically because preview URLs are ephemeral and expire after a set time-to-live (TTL).
class DeezerImporter
  BASE_URL = "https://api.deezer.com"

  def self.import_artist(artist_name)
    new.import_artist(artist_name)
  end

  def self.refresh_track(track)
    return track unless track.deezer_id
    new.refresh_track(track)
  end

  def import_artist(artist_name)
    # Search for the most relevant artist match to begin the ingestion tree.
    search_url = "#{BASE_URL}/search/artist?q=#{URI.encode_www_form_component(artist_name)}"
    search_results = get_json(search_url)

    artist_data = search_results['data']&.first
    return _log_missing_artist(artist_name) unless artist_data

    artist = _upsert_artist(artist_data)
    _import_top_tracks(artist)
    
    artist
  rescue => e
    # Rationale: Fail-soft approach for bulk imports ensures one failing artist doesn't stall the entire pipeline.
    Rails.logger.error "Ingestion pipeline failure for #{artist_name}: #{e.message}"
    nil
  end

  def refresh_track(track)
    return track unless track.deezer_id
    
    # Rationale: Preview URLs provided by Deezer have a strict expiry. 
    # We refresh only when the player requests the track to minimize API overhead.
    track_data = get_json("#{BASE_URL}/track/#{track.deezer_id}")
    return track if _api_error?(track_data)

    track.update!(
      preview_url: track_data['preview'],
      duration_seconds: track_data['duration']
    )
    track
  rescue => e
    Rails.logger.warn "Deferred refresh failed for track #{track.id}: #{e.message}"
    track
  end

  private

  def _upsert_artist(data)
    id = data['id'].to_s
    artist = Artist.find_by(deezer_id: id) || Artist.find_by(name: data['name'], deezer_id: nil) || Artist.new(deezer_id: id)
    
    artist.update!(
      deezer_id: id,
      name: data['name'],
      image_url: data['picture_medium']
    )
    artist
  end

  def _import_top_tracks(artist)
    # Limit to 25 tracks to maintain a balance between library depth and ingestion time.
    results = get_json("#{BASE_URL}/artist/#{artist.deezer_id}/top?limit=25")
    return unless results['data']

    results['data'].each do |data|
      album = _upsert_album(data['album'], artist)
      _upsert_track(data, album)
    end
  end

  def _upsert_album(data, artist)
    id = data['id'].to_s
    album = Album.find_by(deezer_id: id) || Album.find_by(title: data['title'], artist_id: artist.id, deezer_id: nil) || Album.new(deezer_id: id)
    
    album.update!(
      deezer_id: id,
      title: data['title'],
      artist: artist,
      cover_url: data['cover_medium']
    )
    album
  end

  def _upsert_track(data, album)
    id = data['id'].to_s
    track = Track.find_by(deezer_id: id) || Track.find_by(title: data['title'], album_id: album.id, deezer_id: nil) || Track.new(deezer_id: id)
    
    track.update!(
      deezer_id: id,
      title: data['title'],
      album: album,
      duration_seconds: data['duration'],
      preview_url: data['preview']
    )
  end

  def _api_error?(data)
    data.nil? || data['error'].present?
  end

  def _log_missing_artist(name)
    Rails.logger.warn "Metadata lookup failed for artist: #{name}"
    nil
  end

  def get_json(url)
    response = Net::HTTP.get(URI(url))
    JSON.parse(response)
  end
end
