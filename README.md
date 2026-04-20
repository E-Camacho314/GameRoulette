# GameRoulette

<div align="center">

[![GitHub stars](https://img.shields.io/github/stars/E-Camacho314/GameRoulette?style=for-the-badge)](https://github.com/E-Camacho314/GameRoulette/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/E-Camacho314/GameRoulette?style=for-the-badge)](https://github.com/E-Camacho314/GameRoulette/network)
[![GitHub issues](https://img.shields.io/github/issues/E-Camacho314/GameRoulette?style=for-the-badge)](https://github.com/E-Camacho314/GameRoulette/issues)
[![GitHub license](https://img.shields.io/github/license/E-Camacho314/GameRoulette?style=for-the-badge)](LICENSE)

</div>

## Overview

GameRoulette is a full-stack iOS app by Erik Camacho and Thienban Nguyen that connects to your Steam library and recommends what to play next. Build a personal library, set priorities, mark games complete, and hit the roulette button to get a smart, ranked list of what to play; powered by a content-based filtering algorithm running on a Go backend.

NOTE: Firebase is used in the Go backend. Steam IDs are provided in the .txt file for testing.

## Features

- **Steam Integration** - Browse and search Steam's full catalog, pull in details, screenshots, genres, and descriptions
- **Personal Library** - Add games, set priority (High / Medium / Low), and mark them complete; toggle between grid and list view
- **Smart Recommendations** - Content-based filtering using TF-IDF weighted cosine similarity + Maximal Marginal Relevance (MMR) to surface relevant *and* diverse picks
- **Roulette Mode** - Get 5 ranked recommendations from your library; falls back to Steam catalog for new users
- **Developer Map** - View the real-world location of a game's developer studio on an interactive map
- **Theming** - Customizable UI themes with light and dark modes

## Tech Stack

**Frontend**
- <img src="https://img.shields.io/badge/Swift-FA7343?style=for-the-badge&logo=swift&logoColor=white" alt="Swift"/>
- <img src="https://img.shields.io/badge/SwiftUI-007AFF?style=for-the-badge&logo=apple&logoColor=white" alt="SwiftUI"/>
- MapKit (interactive developer studio map)

**Backend**
- <img src="https://img.shields.io/badge/Go-00ADD8?style=for-the-badge&logo=go&logoColor=white" alt="Go"/>
- <img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker"/>
- Google Cloud Firestore (user library persistence)
- Steam Web API (game catalog + details proxy)

## Project Structure

```
GameRoulette/
├── backend/                          # Go REST API
│   ├── main.go                       # HTTP handlers, Firestore CRUD, server setup
│   ├── recommendation.go             # Recommendation algorithm (TF-IDF + MMR)
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── go.mod
│   └── go.sum
│
└── GameRoulette/                     # SwiftUI iOS app
    ├── Models/
    │   ├── BackendService.swift      # HTTP client for Go backend (X-API-Key auth)
    │   ├── LibraryGameModel.swift    # LibraryGame model + LibraryManager
    │   ├── SteamService.swift        # Steam API calls proxied through Go backend
    │   └── Theme.swift               # Theme definitions + ThemeManager
    ├── ViewModels/
    │   ├── RecommendationViewModel.swift
    │   ├── LibraryViewModel.swift
    │   └── SteamGamesViewModel.swift
    └── Views/
        ├── GameRouletteApp.swift     # App entry point
        ├── MainTabView.swift
        ├── WelcomeView.swift         # Login / session restore
        ├── LoginView.swift           # Steam ID input flow
        ├── LibraryView.swift         # Grid / list toggle library
        ├── RecommendationView.swift
        ├── SteamGamesView.swift
        ├── GameDetailsView.swift
        ├── GameCard.swift            # Reusable game card component
        ├── GameDetailLoaderView.swift
        ├── MapView.swift             # Developer studio location map
        └── SettingsView.swift        # Theme picker + account management
```

## Quick Start

### iOS App

> **Note:** The backend is already running on a hosted server; no backend setup is required to run the iOS app.

#### Prerequisites

- A Mac running macOS 13 or later
- Xcode 15 or later ([download from the Mac App Store](https://apps.apple.com/us/app/xcode/id497799835))
- An iPhone or iPad running iOS 16+, or use the built-in Xcode Simulator
- A Steam account with a **public** profile and at least one game in your library

> **Note:** No API keys or credential files are needed. The `BACKEND_API_KEY` is already set in `Info.plist` and the Go backend is hosted; just build and run.

#### Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/E-Camacho314/GameRoulette.git
   cd GameRoulette
   ```

2. **Open the project in Xcode**
   ```bash
   open GameRoulette.xcodeproj
   ```

3. **Select a run destination**
   - In the Xcode toolbar, click the device picker next to the project name
   - Choose an iPhone simulator (e.g. iPhone 15) or your connected physical device
   - If using a physical device, sign in to your Apple account under **Xcode → Settings → Accounts** and select your personal team under **Signing & Capabilities**

4. **Build and run**
   - Press `Cmd+R` or click the play button in the toolbar
   - Xcode will compile the app and launch it on the selected simulator or device

5. **Log in with your Steam ID**
   - On the Welcome screen, tap **Continue with Steam**
   - If this is your first time, you will be prompted to enter your Steam ID
   - Your Steam ID is the 17-digit number in your profile URL (e.g. `https://steamcommunity.com/profiles/76561198000000000/` → `76561198000000000`)
   - Make sure your Steam profile privacy is set to **Public** so your game library can be fetched

6. **Start using the app**
   - Your Steam library will sync automatically on first login
   - Browse your library, set priorities, and use the Roulette tab for recommendations

---

### Self-Hosting the Backend (optional)

Skip this section if you just want to run the iOS app - the hosted backend handles everything.

#### Prerequisites

- Go 1.26+
- A [Steam API key](https://steamcommunity.com/dev/apikey)
- A Firebase project with Firestore enabled and a service account JSON key
- Docker (optional, recommended for Raspberry Pi / ARM64 deployments)

#### Local (no Docker)

```bash
cd backend

export STEAM_API_KEY="your_steam_api_key"
export API_KEY="your_chosen_api_key"
export FIREBASE_CREDENTIALS='{ ...your service account JSON... }'

go run .
# Server starts on :8080
```

#### Docker (recommended for ARM64 / Raspberry Pi 4)

Create `backend/.env` (gitignored):
```env
STEAM_API_KEY=your_steam_api_key
API_KEY=your_chosen_api_key
FIREBASE_CREDENTIALS={ ...your service account JSON... }
```

Place your Firebase service account file at `backend/firebase-service-account.json`, then:

```bash
cd backend
docker compose up --build -d
# Server starts on :8080
```

After standing up your own backend, update `BackendService.baseURL` in `GameRoulette/Models/BackendService.swift` and set `BACKEND_API_KEY` in `Info.plist` to match your `API_KEY`.

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/steam/apps` | Proxy - full Steam game catalog |
| `GET` | `/steam/appdetails?appids=<id>` | Proxy - game details from Steam Store |
| `GET` | `/steam/mygames?steamID=<id>` | Proxy - games owned by a Steam user |
| `GET` | `/library?userID=<id>` | Fetch user's saved library |
| `POST` | `/library?userID=<id>` | Add a game to the library |
| `DELETE` | `/library/{gameID}?userID=<id>` | Remove a game |
| `PATCH` | `/library/{gameID}?userID=<id>` | Update game priority |
| `GET` | `/recommend?userID=<id>` | Get top 5 recommended games |

## Recommendation Algorithm

The `/recommend` endpoint runs a three-stage pipeline:

1. **Cold start guard** - if fewer than 3 non-complete games exist, returns them sorted by priority (no scoring)
2. **TF-IDF scoring** - genres are weighted by how distinctive they are in the user's library (rare genres the user specifically collected score higher than generic ones like "Indie" or "Action")
3. **MMR selection** - instead of returning the top 5 scores directly, Maximal Marginal Relevance iteratively picks games that balance relevance (λ=0.7) against redundancy with already-selected games, ensuring genre diversity in results

Games marked **Complete** are excluded from recommendations unless the entire library is complete, in which case they are used as the candidate pool.

## Acknowledgments

Authored by [E-Camacho314](https://github.com/E-Camacho314), and [tpnguy](https://github.com/tpnguy).

---

<div align="center">

</div>
