# Resonance Rails Guide

This document outlines the Ruby on Rails core application for Resonance.

## Tech Stack
- **Framework**: Ruby on Rails 8.x
- **Database**: PostgreSQL (via `pg` gem)
- **Authentication**: Devise
- **Frontend**: Hotwire (Turbo & Stimulus), TailwindCSS
- **Asset Management**: Propshaft, Importmap

## Key Directories
- `app/models/`: Active Record models (Track, Album, Artist, Playlist, User, UserInteraction).
- `app/controllers/`: Handles HTTP requests and integrates with the `resonance-ml` API for recommendations.
- `app/views/`: ERB templates styled with TailwindCSS.
- `config/routes.rb`: Defines the application's routing map.

## Core Models
- **User**: Managed by Devise. Represents a registered user on the platform.
- **Track, Album, Artist**: The core domain models representing the music catalog. These models map to the tables that the ML service also reads from.
- **Playlist & PlaylistTrack**: Allows users to curate collections of tracks.
- **UserInteraction & Like**: Tracks user behavior (what they listen to, what they like) which is crucial for training personalized models in the ML service.

## Frontend (Hotwire)
Resonance avoids heavy JavaScript frameworks (like React or Vue) by utilizing Hotwire.
- **Turbo**: Intercepts link clicks and form submissions, fetching new HTML over the wire and swapping specific DOM elements. This makes the application feel as fast as a Single Page Application without the complexity.
- **Stimulus**: A modest JavaScript framework for when client-side interactivity is strictly necessary (e.g., controlling a custom HTML5 audio player).

## Admin Dashboard
The application utilizes `Avo` (mounted at `/avo` in `routes.rb`) to provide a beautiful, out-of-the-box admin dashboard for managing users, tracks, and metadata without needing to build custom CRUD views.
