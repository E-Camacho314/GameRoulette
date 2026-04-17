package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"

	"cloud.google.com/go/firestore"
	firebase "firebase.google.com/go/v4"
	"google.golang.org/api/option"
)
type LibraryGame struct {
	ID int `json:"id" firestore:"id"`
	Title string `json:"title" firestore:"title"`
	Genres []string `json:"genres" firestore:"genres"`
	Categories []string `json:"categories" firestore:"categories"`
	ContentDescriptors string   `json:"contentDescriptors" firestore:"contentDescriptors"`
	Priority string `json:"priority" firestore:"priority"`
	Description string `json:"description" firestore:"description"`
	HeaderImage string `json:"headerImage" firestore:"headerImage"`
	Developers string `json:"developers" firestore:"developers"`
	Screenshots string `json:"screenshots" firestore:"screenshots"`
	InLibrary bool `json:"inLibrary" firestore:"inLibrary"`
}

type App struct {
	Firestore *firestore.Client
	SteamKey  string
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	data, err := json.MarshalIndent(v, "", "  ")
	if err != nil {
		http.Error(w, "failed to encode response", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	w.Write(append(data, '\n'))
}

// --- Steam proxy handlers ---

const steamStoreBase = "https://store.steampowered.com/api"
const steamAPIBase = "https://api.steampowered.com"

func (a *App) steamAppDetails(w http.ResponseWriter, r *http.Request) {
	appids := r.URL.Query().Get("appids")
	if appids == "" {
		http.Error(w, "appids required", http.StatusBadRequest)
		return
	}
	upstream := fmt.Sprintf("%s/appdetails?appids=%s", steamStoreBase, appids)
	resp, err := http.Get(upstream)
	if err != nil {
		http.Error(w, "steam request failed", http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()
	w.Header().Set("Content-Type", "application/json")
	io.Copy(w, resp.Body)
}

func (a *App) steamAllApps(w http.ResponseWriter, r *http.Request) {
	if a.SteamKey == "" {
		http.Error(w, "STEAM_API_KEY not configured", http.StatusServiceUnavailable)
		return
	}
	// Key intentionally kept out of log output
	upstream := fmt.Sprintf("%s/IStoreService/GetAppList/v1/?key=%s", steamAPIBase, a.SteamKey)
	resp, err := http.Get(upstream)
	if err != nil {
		http.Error(w, "steam request failed", http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(resp.StatusCode)
	io.Copy(w, resp.Body)
}

func (a *App) steamOwnedGames(w http.ResponseWriter, r *http.Request) {
	if a.SteamKey == "" {
		http.Error(w, "STEAM_API_KEY not configured", http.StatusServiceUnavailable)
		return
	}

	steamID := strings.TrimSpace(r.URL.Query().Get("steamID"))
	if steamID == "" {
		http.Error(w, "steamID required", http.StatusBadRequest)
		return
	}

	upstream := fmt.Sprintf("%s/IPlayerService/GetOwnedGames/v1/?key=%s&steamid=%s&include_appinfo=true&include_played_free_games=true", steamAPIBase, a.SteamKey, steamID)
	resp, err := http.Get(upstream)
	if err != nil {
		http.Error(w, "steam request failed", http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(resp.StatusCode)
	io.Copy(w, resp.Body)
}

func (a *App) getLibrary(w http.ResponseWriter, r *http.Request) {
	userID := r.URL.Query().Get("userID")
	if userID == "" {
		http.Error(w, "userID required", http.StatusBadRequest)
		return
	}

	docs, err := a.Firestore.Collection("users").Doc(userID).Collection("library").Documents(r.Context()).GetAll()
	if err != nil {
		http.Error(w, "failed to fetch library", http.StatusInternalServerError)
		return
	}

	games := make([]LibraryGame, 0, len(docs))
	for _, doc := range docs {
		var g LibraryGame
		if err := doc.DataTo(&g); err != nil {
			log.Printf("skipping doc %s: %v", doc.Ref.ID, err)
			continue
		}
		games = append(games, g)
	}
	writeJSON(w, http.StatusOK, games)
}

func (a *App) addGame(w http.ResponseWriter, r *http.Request) {
	userID := r.URL.Query().Get("userID")
	if userID == "" {
		http.Error(w, "userID required", http.StatusBadRequest)
		return
	}

	r.Body = http.MaxBytesReader(w, r.Body, 1<<20) // 1 MB limit
	var game LibraryGame
	if err := json.NewDecoder(r.Body).Decode(&game); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}

	docID := fmt.Sprintf("%d", game.ID)
	_, err := a.Firestore.Collection("users").Doc(userID).Collection("library").Doc(docID).Set(r.Context(), game)
	if err != nil {
		http.Error(w, "failed to save game", http.StatusInternalServerError)
		return
	}
	writeJSON(w, http.StatusCreated, game)
}

func (a *App) removeGame(w http.ResponseWriter, r *http.Request) {
	userID := r.URL.Query().Get("userID")
	if userID == "" {
		http.Error(w, "userID required", http.StatusBadRequest)
		return
	}
	gameID := r.PathValue("gameID")

	_, err := a.Firestore.Collection("users").Doc(userID).Collection("library").Doc(gameID).Delete(r.Context())
	if err != nil {
		http.Error(w, "failed to delete game", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (a *App) updatePriority(w http.ResponseWriter, r *http.Request) {
	userID := r.URL.Query().Get("userID")
	if userID == "" {
		http.Error(w, "userID required", http.StatusBadRequest)
		return
	}
	gameID := r.PathValue("gameID")

	var body struct {
		Priority string `json:"priority"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Priority == "" {
		http.Error(w, "priority required", http.StatusBadRequest)
		return
	}

	_, err := a.Firestore.Collection("users").Doc(userID).Collection("library").Doc(gameID).Update(r.Context(), []firestore.Update{
		{Path: "priority", Value: body.Priority},
	})
	if err != nil {
		http.Error(w, "failed to update priority", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusOK)
}

// responseWriter wraps http.ResponseWriter to capture the status code for logging
type responseWriter struct {
	http.ResponseWriter
	status int
}

func (rw *responseWriter) WriteHeader(status int) {
	rw.status = status
	rw.ResponseWriter.WriteHeader(status)
}

func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		rw := &responseWriter{ResponseWriter: w, status: http.StatusOK}
		next.ServeHTTP(rw, r)
		log.Printf("%s %s → %d", r.Method, r.URL.String(), rw.status)
	})
}

func (a *App) health(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{
		"ok":      true,
		"service": "gameroulette-backend",
	})
}

func (a *App) routes() http.Handler {
	mux := http.NewServeMux()

	mux.HandleFunc("GET /health", a.health)

	// Steam proxy
	mux.HandleFunc("GET /steam/apps", a.steamAllApps)
	mux.HandleFunc("GET /steam/appdetails", a.steamAppDetails)
	mux.HandleFunc("GET /steam/owned", a.steamOwnedGames)

	// Library CRUD
	mux.HandleFunc("GET /library", a.getLibrary)
	mux.HandleFunc("POST /library", a.addGame)
	mux.HandleFunc("DELETE /library/{gameID}", a.removeGame)
	mux.HandleFunc("PATCH /library/{gameID}", a.updatePriority)

	return loggingMiddleware(mux)
}

func firebaseOptionFromEnv() (option.ClientOption, error) {
	if credsFile := strings.TrimSpace(os.Getenv("GOOGLE_APPLICATION_CREDENTIALS")); credsFile != "" {
		return option.WithCredentialsFile(credsFile), nil
	}

	if credsJSON := strings.TrimSpace(os.Getenv("FIREBASE_CREDENTIALS")); credsJSON != "" {
		return option.WithCredentialsJSON([]byte(credsJSON)), nil
	}

	return nil, fmt.Errorf("set GOOGLE_APPLICATION_CREDENTIALS or FIREBASE_CREDENTIALS")
}

func main() {
	ctx := context.Background()

	steamKey := os.Getenv("STEAM_API_KEY")
	if steamKey == "" {
		log.Println("Warning: STEAM_API_KEY not set; /steam/apps will return 503")
	}

	opt, err := firebaseOptionFromEnv()
	if err != nil {
		log.Fatal(err)
	}

	fbApp, err := firebase.NewApp(ctx, &firebase.Config{ProjectID: "gameroulette-c920a"}, opt)
	if err != nil {
		log.Fatalf("firebase.NewApp: %v", err)
	}

	fsClient, err := fbApp.Firestore(ctx)
	if err != nil {
		log.Fatalf("firestore client: %v", err)
	}
	defer fsClient.Close()

	app := &App{
		Firestore: fsClient,
		SteamKey:  steamKey,
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Server listening on :%s", port)
	if err := http.ListenAndServe(":"+port, app.routes()); err != nil {
		log.Fatal(err)
	}
}
