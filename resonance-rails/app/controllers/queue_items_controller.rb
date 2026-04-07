class QueueItemsController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token, only: [:create] # Simplified for JS fetch

  def index
    @queue_items = current_user.queue_items.includes(track: [:artist, :album])
  end

  def create
    @track = Track.find(params[:track_id])
    @queue_item = current_user.queue_items.new(track: @track)

    if @queue_item.save
      render json: { success: true, message: "Added #{@track.title} to queue" }
    else
      render json: { success: false, message: @queue_item.errors[:track_id].first || "Error adding to queue" }, status: :unprocessable_entity
    end
  end

  def destroy
    @queue_item = current_user.queue_items.find(params[:id])
    @queue_item.destroy
    
    respond_to do |format|
      format.html { redirect_to queue_items_path, notice: "Removed from queue" }
      format.turbo_stream
    end
  end
end
