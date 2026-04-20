# GameRoulette

<div align="center">

[![GitHub stars](https://img.shields.io/github/stars/E-Camacho314/GameRoulette?style=for-the-badge)](https://github.com/E-Camacho314/GameRoulette/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/E-Camacho314/GameRoulette?style=for-the-badge)](https://github.com/E-Camacho314/GameRoulette/network)
[![GitHub issues](https://img.shields.io/github/issues/E-Camacho314/GameRoulette?style=for-the-badge)](https://github.com/E-Camacho314/GameRoulette/issues)
[![GitHub license](https://img.shields.io/github/license/E-Camacho314/GameRoulette?style=for-the-badge)](LICENSE)

</div>

## Overview

GameRoulette is a full-stack iOS app that connects to your Steam library and recommends what to play next. Build a personal library, set priorities, mark games complete, and hit the roulette button to get a smart, ranked list of what to play; powered by a content-based filtering algorithm running on a Go backend.

NOTE: Firebase is used in the Go backend. Steam IDs are provided in the .txt file for testing.

## Features

-  **Steam Integration** - Browse and search Steam's full catalog, pull in details, screenshots, genres, and descriptions
-  **Personal Library** - Add games, set priority (High / Medium / Low), and mark them complete
-  **Smart Recommendations** - Content-based filtering using TF-IDF weighted cosine similarity + Maximal Marginal Relevance (MMR) to surface relevant *and* diverse picks
-  **Roulette Mode** - Get 5 ranked recommendations from your library; falls back to Steam catalog for new users
-  **Theming** - Customizable UI themes

##  Tech Stack

**Frontend**
- <img src="https://img.shields.io/badge/Swift-FA7343?style=for-the-badge&logo=swift&logoColor=white" alt="Swift"/>
- <img src="https://img.shields.io/badge/SwiftUI-007AFF?style=for-the-badge&logo=apple&logoColor=white" alt="SwiftUI"/>
- Firebase iOS SDK (authentication)

**Backend**
- <img src="https://img.shields.io/badge/Go-00ADD8?style=for-the-badge&logo=go&logoColor=white" alt="Go"/>
- <img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker"/>
- Google Cloud Firestore (user library persistence)
- Steam Web API (game catalog + details proxy)

##  Project Structure

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
    │   ├── BackendService.swift      # HTTP client for Go backend
    │   ├── LibraryGameModel.swift    # LibraryGame model + LibraryManager
    │   └── SteamService.swift        # Direct Steam API calls
    ├── ViewModels/
    │   ├── RecommendationViewModel.swift
    │   ├── LibraryViewModel.swift
    │   └── SteamGamesViewModel.swift
    └── Views/
        ├── MainTabView.swift
        ├── RecommendationView.swift
        ├── LibraryView.swift
        ├── SteamGamesView.swift
        └── GameDetailsView.swift
```

##  Quick Start

### Prerequisites

- macOS with Xcode (latest stable)
- Go 1.22+
- A [Steam API key](https://steamcommunity.com/dev/apikey)
- A Firebase project with Firestore enabled and a service account JSON key

### Backend (local)

```bash
cd backend

export STEAM_API_KEY="your_steam_api_key"
export FIREBASE_CREDENTIALS='{ ...your service account JSON... }'

go run .
# Server starts on :8080
```

### Backend (Docker)

Create `backend/.env` (gitignored):
```env
STEAM_API_KEY=your_steam_api_key
FIREBASE_CREDENTIALS={ ...your service account JSON... }
```

Then:
```bash
cd backend
docker compose up --build
# Server starts on :8080
```

### iOS App

1. Open `GameRoulette.xcodeproj` in Xcode
2. Add your `GoogleService-Info.plist` (Firebase config) to the `GameRoulette/` folder; this file is gitignored
3. *(Optional)* Create `GameRoulette/Secrets.swift` to pre-fill your Steam ID at build time:
   ```swift
   enum Secrets {
       static var steamID = "your_steam_id"
   }
   ```
   If this file is absent, the app's Welcome screen will prompt you to enter your Steam ID manually on first launch; no file required.
4. In `BackendService.swift`, set the production URL for Release builds
5. Select a simulator or device and press `Cmd+R`

##  API Endpoints

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

##  Recommendation Algorithm

The `/recommend` endpoint runs a three-stage pipeline:

1. **Cold start guard** - if fewer than 3 non-complete games exist, returns them sorted by priority (no scoring)
2. **TF-IDF scoring** - genres are weighted by how distinctive they are in the user's library (rare genres the user specifically collected score higher than generic ones like "Indie" or "Action")
3. **MMR selection** - instead of returning the top 5 scores directly, Maximal Marginal Relevance iteratively picks games that balance relevance (λ=0.7) against redundancy with already-selected games, ensuring genre diversity in results

Games marked **Complete** are excluded from recommendations unless the entire library is complete, in which case they are used as the candidate pool.

##  Acknowledgments

Authored by [E-Camacho314](https://github.com/E-Camacho314), and [tpnguy](https://github.com/tpnguy).

---

<div align="center">

</div>
