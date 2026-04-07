import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "title", "artist", "cover",
    "playBtn", "playIcon",
    "progressBar", "progressFill",
    "currentTime", "duration",
    "volume", "volumeFill",
    "repeatBtn", "shuffleBtn",
    
    // Full Player Targets
    "container", "miniPlayer", "fullPlayer",
    "fullTitle", "fullArtist", "fullCover", "fullBg",
    "fullProgressFill", "fullCurrentTime", "fullDuration",
    "fullPlayIcon", "fullRepeatBtn", "fullShuffleBtn",
    "fullContext"
  ]

  static values = {
    trackId: Number,
    contextType: String,
    contextId: String
  }

  connect() {
    this.initializeAudio()
    this.setupEventListeners()
    this.syncUI()
    
    console.log("Player Controller Connected (Persistent Mode)")
  }

  disconnect() {
    this.removeEventListeners()
    // We explicitly DO NOT pause audio here to allow persistent playback
  }

  initializeAudio() {
    if (!window.resonanceAudio) {
      window.resonanceAudio = new Audio()
      window.resonancePlaying = false
      window.resonanceRepeat = false
      window.resonanceShuffle = false
    }
    
    this.audio = window.resonanceAudio
    this.playing = window.resonancePlaying
    this.repeat = window.resonanceRepeat
    this.shuffle = window.resonanceShuffle
  }

  setupEventListeners() {
    // Audio listeners
    this.onTimeUpdate = () => this.updateProgress()
    this.onLoadedMetadata = () => this.updateDuration()
    this.onAudioEnded = () => this.handleEnded()
    this.onAudioError = (e) => this.handleAudioError(e)

    this.audio.addEventListener("timeupdate", this.onTimeUpdate)
    this.audio.addEventListener("loadedmetadata", this.onLoadedMetadata)
    this.audio.addEventListener("ended", this.onAudioEnded)
    this.audio.addEventListener("error", this.onAudioError)

    // Global action listeners
    this.onPlayTrack = (e) => this.loadTrack(e.detail)
    this.onPlayRow = (e) => this.handlePlayRowEvent(e)
    this.onAddToQueue = (e) => this.addToQueue(e.detail)
    
    document.addEventListener("player:play", this.onPlayTrack)
    document.addEventListener("player:playRow", this.onPlayRow)
    document.addEventListener("player:addToQueue", this.onAddToQueue)
    document.addEventListener("fullscreenchange", () => this.handleFullscreenChange())
  }

  removeEventListeners() {
    if (this.audio) {
      this.audio.removeEventListener("timeupdate", this.onTimeUpdate)
      this.audio.removeEventListener("loadedmetadata", this.onLoadedMetadata)
      this.audio.removeEventListener("ended", this.onAudioEnded)
      this.audio.removeEventListener("error", this.onAudioError)
    }
    document.removeEventListener("player:play", this.onPlayTrack)
    document.removeEventListener("player:playRow", this.onPlayRow)
  }

  syncUI() {
    if (window.resonanceCurrentTrack) {
      this.syncMetadata(window.resonanceCurrentTrack.title, window.resonanceCurrentTrack.artist, window.resonanceCurrentTrack.cover)
      this.trackIdValue = window.resonanceCurrentTrack.trackId
    }
    
    const isPlaying = !this.audio.paused && this.audio.src !== ""
    this.playing = isPlaying
    window.resonancePlaying = isPlaying
    
    this.updatePlayIcon()
    this.updateProgress()
    this.updateDuration()
    
    if (this.hasRepeatBtnTarget) this.repeatBtnTarget.classList.toggle("text-brand-primary", this.repeat)
    if (this.hasShuffleBtnTarget) this.shuffleBtnTarget.classList.toggle("text-brand-primary", this.shuffle)
  }

  handlePlayRowEvent(e) {
    this.playRow(e.detail.trackId, e.detail.contextType, e.detail.contextId)
  }

  playRow(trackId, contextType = null, contextId = null) {
    if (!trackId) return

    console.log(`Fetching playback for track: ${trackId} (Context: ${contextType})`)
    
    // Set context
    this.contextTypeValue = contextType || ""
    this.contextIdValue = contextId || ""

    
    fetch(`/tracks/${trackId}/playback`)
      .then(response => response.json())
      .then(data => {
        this.loadTrack(data)
      })
      .catch(err => {
        console.error("Playback fetch failed:", err)
      })
  }

  loadTrack(detail) {
    const { title, artist, cover, preview, trackId } = detail
    
    if (!preview || preview.trim() === "") {
      console.warn("No preview URL provided for track:", title)
      return
    }

    // Persist the outgoing track's play duration before we load the new one
    if (this.trackIdValue && this.audio.src && this.trackIdValue !== trackId) {
      this.persistInteraction('switch')
    }

    console.log(`Loading track: ${title} - ${artist}`)

    window.resonanceCurrentTrack = { title, artist, cover, preview, trackId }
    this.syncMetadata(title, artist, cover)
    this.trackIdValue = trackId

    const absolutePreview = new URL(preview, window.location.origin).href
    if (this.audio.src !== absolutePreview) {
      this.audio.src = preview
      this.audio.load()
    }

    this.playAudio()
  }

  syncMetadata(title, artist, cover) {
    // Mini
    if (this.hasTitleTarget) this.titleTarget.textContent = title
    if (this.hasArtistTarget) this.artistTarget.textContent = artist
    if (this.hasCoverTarget) this.coverTarget.src = cover || "https://picsum.photos/seed/default/200/200"
    
    // Full
    if (this.hasFullTitleTarget) this.fullTitleTarget.textContent = title
    if (this.hasFullArtistTarget) this.fullArtistTarget.textContent = artist
    if (this.hasFullCoverTarget) this.fullCoverTarget.src = cover || ""
    if (this.hasFullBgTarget) this.fullBgTarget.src = cover || ""
  }

  togglePlay() {
    if (!this.audio.src || this.audio.src === window.location.href) return

    if (this.playing) {
      this.audio.pause()
      this.playing = false
      window.resonancePlaying = false
      this.updatePlayIcon()
    } else {
      this.playAudio()
    }
  }

  playAudio() {
    this.audio.play()
      .then(() => {
        this.playing = true
        window.resonancePlaying = true
        this.updatePlayIcon()
      })
      .catch(err => {
        console.error("Playback Error:", err)
        this.playing = false
        window.resonancePlaying = false
        this.updatePlayIcon()
      })
  }

  updatePlayIcon() {
    const iconName = this.playing ? "pause" : "play"
    
    if (this.hasPlayIconTarget) this.playIconTarget.setAttribute("data-lucide", iconName)
    if (this.hasFullPlayIconTarget) this.fullPlayIconTarget.setAttribute("data-lucide", iconName)
    
    if (window.lucide) window.lucide.createIcons()
  }

  handleAudioError(e) {
    if (this.audio.src) {
      console.error("Audio element error:", this.audio.error)
      this.playing = false
      window.resonancePlaying = false
      this.updatePlayIcon()
    }
  }

  skipNext() {
    if (!this.trackIdValue) return
    
    // We don't check for queue here anymore because the server (TracksController#next)
    // now prioritizes the database queue automatically.
    
    this.persistInteraction('skip')
    
    const params = new URLSearchParams({
      context_type: this.contextTypeValue || "",
      context_id: this.contextIdValue || "",
      shuffle: this.shuffle ? "true" : "false"
    })

    fetch(`/tracks/${this.trackIdValue}/next?${params.toString()}`)
      .then(r => r.json())
      .then(data => this.loadTrack(data))
      .catch(err => console.error("Skip Next failed:", err))
  }

  skipPrev() {
    if (!this.trackIdValue) return
    this.persistInteraction('skip')
    
    const params = new URLSearchParams({
      context_type: this.contextTypeValue || "",
      context_id: this.contextIdValue || ""
    })

    fetch(`/tracks/${this.trackIdValue}/prev?${params.toString()}`)
      .then(r => r.json())
      .then(data => this.loadTrack(data))
      .catch(err => console.error("Skip Prev failed:", err))
  }

  persistInteraction(action = 'play') {
    if (!this.trackIdValue) return

    const duration = this.audio.duration || 0
    const currentTime = this.audio.currentTime || 0
    const percentage = duration > 0 ? Math.min(1.0, currentTime / duration) : 0
    
    // Neural Session Management: 30-minute idle heuristic
    const now = Date.now()
    const lastInteraction = parseInt(localStorage.getItem('resonance_last_interaction') || '0')
    const idleTime = now - lastInteraction
    let sessionId = localStorage.getItem('resonance_session_id')

    if (!sessionId || idleTime > (30 * 60 * 1000)) {
      sessionId = crypto.randomUUID()
      localStorage.setItem('resonance_session_id', sessionId)
      console.log(`Neural Session Reset: ${sessionId}`)
    }
    localStorage.setItem('resonance_last_interaction', now.toString())

    fetch("/interactions", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        track_id: this.trackIdValue,
        action: action,
        session_id: sessionId,
        completion_percentage: percentage,
        listen_duration: Math.round(currentTime)
      })
    }).then(response => {
      if (!response.ok) console.warn("Failed to persist interaction")
    }).catch(err => {
      console.error("Interaction Persistence Error:", err)
    })
  }

  toggleRepeat() {
    this.repeat = !this.repeat
    this.audio.loop = this.repeat
    
    const targets = [
      this.hasRepeatBtnTarget ? this.repeatBtnTarget : null,
      this.hasFullRepeatBtnTarget ? this.fullRepeatBtnTarget : null
    ].filter(Boolean)

    targets.forEach(t => {
      t.classList.toggle("text-brand-primary", this.repeat)
      t.classList.toggle("text-slate-500", !this.repeat)
    })
  }

  toggleShuffle() {
    this.shuffle = !this.shuffle
    const targets = [
      this.hasShuffleBtnTarget ? this.shuffleBtnTarget : null,
      this.hasFullShuffleBtnTarget ? this.fullShuffleBtnTarget : null
    ].filter(Boolean)

    targets.forEach(t => {
      t.classList.toggle("text-brand-primary", this.shuffle)
      t.classList.toggle("text-slate-500", !this.shuffle)
    })
  }

  setVolume(event) {
    if (!this.hasVolumeTarget) return
    const rect = this.volumeTarget.getBoundingClientRect()
    const vol = Math.max(0, Math.min(1, (event.clientX - rect.left) / rect.width))
    this.audio.volume = vol
    if (this.hasVolumeFillTarget) {
      this.volumeFillTarget.style.width = (vol * 100) + "%"
    }
  }

  toggleFullscreen() {
    if (!document.fullscreenElement) {
      const target = this.hasContainerTarget ? this.containerTarget : this.element
      target.requestFullscreen().catch(err => {
        console.error(`Error attempting to enable full-screen mode: ${err.message}`)
      })
    } else {
      document.exitFullscreen()
    }
  }

  handleFullscreenChange() {
    const target = this.hasContainerTarget ? this.containerTarget : this.element
    const isFull = document.fullscreenElement === target

    if (isFull) {
      if (this.hasMiniPlayerTarget) this.miniPlayerTarget.classList.add("hidden")
      if (this.hasFullPlayerTarget) this.fullPlayerTarget.classList.remove("hidden")
      target.style.height = "100vh"
      target.style.background = "#05070A"
    } else {
      if (this.hasMiniPlayerTarget) this.miniPlayerTarget.classList.remove("hidden")
      if (this.hasFullPlayerTarget) this.fullPlayerTarget.classList.add("hidden")
      target.style.height = "80px"
      target.style.background = "rgba(8,10,14,0.92)"
    }
    if (window.lucide) window.lucide.createIcons()
  }

  addToQueue(trackDetail) {
    if (!trackDetail || !trackDetail.trackId) return
    
    fetch("/queue", {
      method: "POST",
      headers: { 
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ track_id: trackDetail.trackId })
    })
    .then(async r => {
      const data = await r.json()
      if (r.ok) {
        this.notify(data.message, "notice")
      } else {
        this.notify(data.message || "Could not add to queue", "alert")
      }
    })
    .catch(err => {
      console.error("Queue submission error:", err)
      this.notify("Failed to add to queue", "alert")
    })
  }

  notify(message, type = "notice") {
    const container = document.getElementById("toast-container")
    if (!container) {
      console.warn("Toast container not found, falling back to alert")
      if (type === "alert") alert(message)
      return
    }

    const toast = document.createElement("div")
    toast.setAttribute("data-controller", "toast")
    toast.setAttribute("data-toast-message-value", message)
    toast.setAttribute("data-toast-type-value", type)
    container.appendChild(toast)
  }

  toggleQueue() {
    // Navigate to the "Normal Screen" queue
    Turbo.visit("/queue")
  }

  updateProgress() {
    if (!this.audio.duration || isNaN(this.audio.duration)) return
    const pct = (this.audio.currentTime / this.audio.duration) * 100
    const timeStr = this.formatTime(this.audio.currentTime)
    
    if (this.hasProgressFillTarget) this.progressFillTarget.style.width = pct + "%"
    if (this.hasCurrentTimeTarget) this.currentTimeTarget.textContent = timeStr
    
    if (this.hasFullProgressFillTarget) this.fullProgressFillTarget.style.width = pct + "%"
    if (this.hasFullCurrentTimeTarget) this.fullCurrentTimeTarget.textContent = timeStr
  }

  updateDuration() {
    if (isNaN(this.audio.duration)) return
    const durStr = this.formatTime(this.audio.duration)
    if (this.hasDurationTarget) this.durationTarget.textContent = durStr
    if (this.hasFullDurationTarget) this.fullDurationTarget.textContent = durStr
  }

  handleEnded() {
    if (this.repeat) return
    this.persistInteraction('complete')
    this.skipNext()
  }

  seek(event) {
    if (!this.audio.duration || isNaN(this.audio.duration)) return
    const rect = event.currentTarget.getBoundingClientRect()
    const pct = (event.clientX - rect.left) / rect.width
    this.audio.currentTime = pct * this.audio.duration
  }

  stopProp(event) {
    event.stopPropagation()
  }

  formatTime(seconds) {
    if (!seconds || isNaN(seconds)) return "0:00"
    const m = Math.floor(seconds / 60)
    const s = Math.floor(seconds % 60)
    return `${m}:${s.toString().padStart(2, "0")}`
  }
}
