package main

import (
	"log"
	"math"
	"net/http"
	"sort"
)

const mmrLambda = 0.7

func priorityBoost(p string) float64 {
	switch p {
	case "High":
		return 0.3
	case "Medium":
		return 0.2
	case "Low":
		return 0.1
	default:
		return 0.0
	}
}

// gameCosineSim computes cosine similarity between two TF-IDF genre vectors.
func gameCosineSim(a, b map[string]float64) float64 {
	dot, magA, magB := 0.0, 0.0, 0.0
	for genre, wa := range a {
		dot += wa * b[genre]
		magA += wa * wa
	}
	for _, wb := range b {
		magB += wb * wb
	}
	if magA == 0 || magB == 0 {
		return 0
	}
	return dot / (math.Sqrt(magA) * math.Sqrt(magB))
}

func (a *App) recommend(w http.ResponseWriter, r *http.Request) {
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

	var all []LibraryGame
	for _, doc := range docs {
		var g LibraryGame
		if err := doc.DataTo(&g); err != nil {
			log.Printf("skipping doc %s: %v", doc.Ref.ID, err)
			continue
		}
		all = append(all, g)
	}

	candidates := make([]LibraryGame, 0, len(all))
	for _, g := range all {
		if g.Priority != "Complete" {
			candidates = append(candidates, g)
		}
	}
	if len(candidates) == 0 {
		candidates = all
	}

	// Cold start: too few games to build a meaningful profile — sort by priority only.
	if len(candidates) < 3 {
		sort.Slice(candidates, func(i, j int) bool {
			return priorityBoost(candidates[i].Priority) > priorityBoost(candidates[j].Priority)
		})
		writeJSON(w, http.StatusOK, candidates[:min(5, len(candidates))])
		return
	}

	n := float64(len(candidates))

	// Document frequency: how many games have each genre.
	df := make(map[string]int)
	for _, g := range candidates {
		for _, genre := range g.Genres {
			df[genre]++
		}
	}

	// Smoothed IDF: log((N+1) / (df+1))
	idf := make(map[string]float64)
	for genre, count := range df {
		idf[genre] = math.Log((n + 1) / float64(count+1))
	}

	// Profile vector = df[g] * idf[g] per genre. Precompute its magnitude (constant across all games).
	profileMag := 0.0
	for genre, count := range df {
		v := float64(count) * idf[genre]
		profileMag += v * v
	}
	profileMag = math.Sqrt(profileMag)

	type scored struct {
		game LibraryGame
		sim  float64
		vec  map[string]float64 // TF-IDF genre vector, used for MMR redundancy
	}

	pool := make([]scored, len(candidates))
	for i, g := range candidates {
		vec := make(map[string]float64, len(g.Genres))
		dot, gameMagSq := 0.0, 0.0
		for _, genre := range g.Genres {
			w := idf[genre]
			vec[genre] = w
			// dot(game_vec, profile_vec) = idf[g]^2 * df[g]
			dot += w * w * float64(df[genre])
			gameMagSq += w * w
		}
		var cosineSim float64
		if gameMagSq > 0 && profileMag > 0 {
			cosineSim = dot / (math.Sqrt(gameMagSq) * profileMag)
		}
		pool[i] = scored{game: g, sim: cosineSim + priorityBoost(g.Priority), vec: vec}
	}

	// MMR: iteratively pick the game that best balances relevance and diversity.
	selected := make([]scored, 0, 5)
	remaining := make([]scored, len(pool))
	copy(remaining, pool)

	for len(selected) < 5 && len(remaining) > 0 {
		bestIdx, bestScore := 0, math.Inf(-1)
		for i, cand := range remaining {
			redundancy := 0.0
			for _, sel := range selected {
				if s := gameCosineSim(cand.vec, sel.vec); s > redundancy {
					redundancy = s
				}
			}
			mmrScore := mmrLambda*cand.sim - (1-mmrLambda)*redundancy
			if mmrScore > bestScore {
				bestScore = mmrScore
				bestIdx = i
			}
		}
		selected = append(selected, remaining[bestIdx])
		remaining = append(remaining[:bestIdx], remaining[bestIdx+1:]...)
	}

	games := make([]LibraryGame, len(selected))
	for i, s := range selected {
		games[i] = s.game
	}
	writeJSON(w, http.StatusOK, games)
}
