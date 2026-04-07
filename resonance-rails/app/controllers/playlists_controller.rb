class PlaylistsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_playlist, only: [:show, :edit, :update, :destroy]
  before_action :authorize_playlist!, only: [:edit, :update, :destroy]

  def index
    @playlists = current_user.playlists.order(created_at: :desc)
    redirect_to library_path
  end

  def show
  end

  def new
    @playlist = current_user.playlists.build
  end

  def create
    @playlist = current_user.playlists.build(playlist_params)
    if @playlist.save
      redirect_to @playlist, notice: "Playlist created!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @playlist.update(playlist_params)
      redirect_to @playlist, notice: "Playlist updated!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @playlist.destroy
    redirect_to library_path, notice: "Playlist deleted."
  end

  private

  def set_playlist
    @playlist = Playlist.find(params[:id])
  end

  def authorize_playlist!
    redirect_to library_path, alert: "Not authorized." unless @playlist.user == current_user
  end

  def playlist_params
    params.require(:playlist).permit(:title, :description, :image_url)
  end
end
