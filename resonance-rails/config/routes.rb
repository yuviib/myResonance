Rails.application.routes.draw do
  resources :artists, only: [:index, :show]
  resources :albums, only: [:show]
  mount_avo
  devise_for :users

  # Dashboard/Explore
  get "dashboard", to: "home#index", as: :dashboard
  get "recommendations", to: "recommendations#index", as: :recommendations
  
  # New Functional Routes
  get "search", to: "search#index", as: :search
  get "library", to: "library#index", as: :library
  resource :profile, only: [:show, :edit, :update]
  resources :queue_items, only: [:index, :create, :destroy], path: 'queue'
  resources :playlists do
    resources :playlist_tracks, only: [:create, :destroy], shallow: true
  end

  resources :tracks, only: [] do
    resource :like, only: [:create, :destroy], module: :tracks
    member do
      get :next
      get :prev
      get :playback
    end
  end

  resources :interactions, only: [:create]

  # Landing page for guests
  root to: "welcome#index"
  
  get "up" => "rails/health#show", as: :rails_health_check
end
