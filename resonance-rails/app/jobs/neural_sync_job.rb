class NeuralSyncJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "--- [NeuralSyncJob] Initiating Telemetry Export & Training Iteration ---"
    
    # 1. Export UserInteractions to CSV
    export_path = Rails.root.join("../resonance-ml/data/interactions.csv")
    interactions = UserInteraction.all

    if interactions.empty?
      Rails.logger.info "[NeuralSyncJob] No interactions found. Bypassing training."
      return
    end

    require 'csv'
    CSV.open(export_path, "wb") do |csv|
      csv << ["user_identifier", "session_id", "track_id", "action", "completion_percentage", "created_at"]
      interactions.find_each do |interaction|
        csv << [
          interaction.user_identifier,
          interaction.session_id,
          interaction.track_id,
          ((interaction.completion_percentage || 1.0) < 0.2) ? 'skip' : 'play',
          interaction.completion_percentage || 1.0,
          interaction.created_at
        ]
      end
    end
    Rails.logger.info "[NeuralSyncJob] Dumped #{interactions.count} events to CSV."

    # 2. Trigger Python Incremental Epoch
    require 'net/http'
    require 'uri'

    uri = URI.parse("http://localhost:8000/api/v1/train")
    begin
      response = Net::HTTP.post_form(uri, "data_path" => "data/interactions.csv")
      if response.code == "200"
        result = JSON.parse(response.body)
        Rails.logger.info "[NeuralSyncJob] ML Engine Train Success: #{result['status']}"
      else
        Rails.logger.error "[NeuralSyncJob] ML Engine Train Failed: HTTP #{response.code}"
      end
    rescue StandardError => e
      Rails.logger.error "[NeuralSyncJob] Connection to ML Engine failed: #{e.message}"
    end
  end
end
