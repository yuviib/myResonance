# Auto-sync track library to ML Engine on boot
# Since the ML Service TRACK_DATABASE is in-memory, we need to populate it.

Rails.application.config.after_initialize do
  next if ENV["DISABLE_ML_SYNC"].present?

  Thread.new do
    max_retries = 5
    retries = 0

    begin
      # Ping the health endpoint first using built-in Net::HTTP to avoid extra dependencies
      require 'net/http'
      response = Net::HTTP.get_response(URI("http://127.0.0.1:8000/health"))

      if response.is_a?(Net::HTTPSuccess)
        puts "[Resonance] ML Engine is online. Initiating zero-shot track sync..."
        MlClient.sync_all_tracks
      else
        raise "Engine not ready (Status: #{response.code})"
      end
    rescue => e
      retries += 1
      if retries <= max_retries
        delay = retries * 2
        puts "[Resonance] ML Engine warming up... retrying in #{delay} seconds."
        sleep(delay)
        retry
      else
        puts "[Resonance] FATAL: ML Engine failed to boot after #{max_retries} attempts: #{e.message}"
      end
    end
  end
end
