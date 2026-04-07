class InteractionsController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token # For simpler async fetch calls

  def create
    # Immutable Event Log: We always create a new record for every interaction event
    UserInteraction.create!(
      track_id: params[:track_id],
      user_identifier: current_user.email,
      action: params[:action] || 'play',
      session_id: params[:session_id],
      completion_percentage: params[:completion_percentage].to_f,
      listen_duration: params[:listen_duration].to_i
    )

    render json: { status: "success" }
  end
end
