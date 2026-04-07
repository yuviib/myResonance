class TracksController < ApplicationController
  before_action :authenticate_user!

  def next
    track = Track.find(params[:id])
    context_type = params[:context_type]
    context_id = params[:context_id]
    shuffle = params[:shuffle] == "true"

    # 1. First, check the manual queue
    if current_user.queue_items.any?
      queue_item = current_user.queue_items.first
      next_track_obj = queue_item.track
      queue_item.destroy
    else
      # 2. Otherwise use contextual logic
      next_track_obj = if shuffle
        fetch_random_from_context(track, context_type, context_id)
      else
        fetch_sequential_from_context(track, context_type, context_id, :next)
      end
    end

    # Fallback to artist tracks if context fails
    next_track_obj ||= track.artist.tracks.where("tracks.id > ?", track.id).first || track.artist.tracks.first
    
    # Refresh to get fresh URL
    next_track = DeezerImporter.refresh_track(next_track_obj)
    render json: track_json(next_track)
  end

  def prev
    track = Track.find(params[:id])
    context_type = params[:context_type]
    context_id = params[:context_id]
    shuffle = params[:shuffle] == "true"

    prev_track_obj = if shuffle
      fetch_random_from_context(track, context_type, context_id)
    else
      fetch_sequential_from_context(track, context_type, context_id, :prev)
    end

    # Fallback to artist tracks if context fails
    prev_track_obj ||= track.artist.tracks.where("tracks.id < ?", track.id).last || track.artist.tracks.last
    
    # Refresh to get fresh URL
    prev_track = DeezerImporter.refresh_track(prev_track_obj)
    render json: track_json(prev_track)
  end

  def playback
    track = Track.find(params[:id])
    # Fetch fresh preview URL from Deezer
    refreshed_track = DeezerImporter.refresh_track(track)
    render json: track_json(refreshed_track)
  end

  private

  def fetch_sequential_from_context(track, type, id, direction)
    case type
    when "playlist"
      playlist = Playlist.find_by(id: id)
      return nil unless playlist
      pts = playlist.playlist_tracks.order(:position, :created_at)
      current_pt = pts.find_by(track_id: track.id)
      return nil unless current_pt
      
      if direction == :next
        pts.where("position > ? OR (position = ? AND created_at > ?)", current_pt.position, current_pt.position, current_pt.created_at).first&.track
      else
        pts.where("position < ? OR (position = ? AND created_at < ?)", current_pt.position, current_pt.position, current_pt.created_at).last&.track
      end
    when "liked_songs"
      likes = current_user.likes.order(created_at: :desc)
      current_like = likes.find_by(track_id: track.id)
      return nil unless current_like
      
      if direction == :next
        likes.where("created_at < ?", current_like.created_at).first&.track
      else
        likes.where("created_at > ?", current_like.created_at).last&.track
      end
    when "artist"
      artist = track.artist
      if direction == :next
        artist.tracks.where("tracks.id > ?", track.id).first
      else
        artist.tracks.where("tracks.id < ?", track.id).last
      end
    else
      nil
    end
  end

  def fetch_random_from_context(track, type, id)
    case type
    when "playlist"
      Playlist.find_by(id: id)&.tracks&.order("RANDOM()")&.first
    when "liked_songs"
      current_user.tracks&.order("RANDOM()")&.first
    when "artist"
      track.artist.tracks.order("RANDOM()").first
    else
      Track.order("RANDOM()").first
    end
  end

  private

  def track_json(track)
    {
      trackId: track.id,
      title: track.title,
      artist: track.artist.name,
      cover: track.album.cover_url.presence || "https://picsum.photos/seed/#{track.id}/200/200",
      preview: track.preview_url.to_s
    }
  end
end
