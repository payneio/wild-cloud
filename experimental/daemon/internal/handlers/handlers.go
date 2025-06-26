package handlers

import (
	"encoding/json"
	"io"
	"log"
	"net/http"
	"os"
	"time"

	"wild-cloud-central/internal/config"
	"wild-cloud-central/internal/data"
	"wild-cloud-central/internal/dnsmasq"
)

// App represents the application with its dependencies
type App struct {
	Config         *config.Config
	StartTime      time.Time
	DataManager    *data.Manager
	DnsmasqManager *dnsmasq.ConfigGenerator
}

// NewApp creates a new application instance
func NewApp() *App {
	return &App{
		StartTime:      time.Now(),
		DataManager:    data.NewManager(),
		DnsmasqManager: dnsmasq.NewConfigGenerator(),
	}
}

// HealthHandler handles health check requests
func (app *App) HealthHandler(w http.ResponseWriter, r *http.Request) {
	response := map[string]string{
		"status":  "healthy",
		"service": "wild-cloud-central",
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// StatusHandler handles status requests for the UI
func (app *App) StatusHandler(w http.ResponseWriter, r *http.Request) {
	uptime := time.Since(app.StartTime)

	response := map[string]interface{}{
		"status":    "running",
		"version":   "1.0.0",
		"uptime":    uptime.String(),
		"timestamp": time.Now().UnixMilli(),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// GetConfigHandler handles configuration retrieval requests
func (app *App) GetConfigHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	// Always reload config from file on each request
	paths := app.DataManager.GetPaths()
	cfg, err := config.Load(paths.ConfigFile)
	if err != nil {
		log.Printf("Failed to load config from file: %v", err)
		response := map[string]interface{}{
			"configured": false,
			"message":    "No configuration found. Please POST a configuration to /api/v1/config to get started.",
		}
		json.NewEncoder(w).Encode(response)
		return
	}

	// Update the cached config with fresh data
	app.Config = cfg

	// Check if config is empty/uninitialized
	if cfg.IsEmpty() {
		response := map[string]interface{}{
			"configured": false,
			"message":    "Configuration is incomplete. Please complete the setup.",
		}
		json.NewEncoder(w).Encode(response)
		return
	}

	response := map[string]interface{}{
		"configured": true,
		"config":     cfg,
	}
	json.NewEncoder(w).Encode(response)
}

// CreateConfigHandler handles configuration creation requests
func (app *App) CreateConfigHandler(w http.ResponseWriter, r *http.Request) {
	// Only allow config creation if no config exists
	if app.Config != nil && !app.Config.IsEmpty() {
		http.Error(w, "Configuration already exists. Use PUT to update.", http.StatusConflict)
		return
	}

	var newConfig config.Config
	if err := json.NewDecoder(r.Body).Decode(&newConfig); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	// Set defaults
	if newConfig.Server.Port == 0 {
		newConfig.Server.Port = 5055
	}
	if newConfig.Server.Host == "" {
		newConfig.Server.Host = "0.0.0.0"
	}

	app.Config = &newConfig

	// Persist config to file
	paths := app.DataManager.GetPaths()
	if err := config.Save(app.Config, paths.ConfigFile); err != nil {
		log.Printf("Failed to save config: %v", err)
		http.Error(w, "Failed to save config", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "created"})
}

// UpdateConfigHandler handles configuration update requests
func (app *App) UpdateConfigHandler(w http.ResponseWriter, r *http.Request) {
	// Check if config exists
	if app.Config == nil || app.Config.IsEmpty() {
		http.Error(w, "No configuration exists. Use POST to create initial configuration.", http.StatusNotFound)
		return
	}

	var newConfig config.Config
	if err := json.NewDecoder(r.Body).Decode(&newConfig); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	app.Config = &newConfig

	// Persist config to file
	paths := app.DataManager.GetPaths()
	if err := config.Save(app.Config, paths.ConfigFile); err != nil {
		log.Printf("Failed to save config: %v", err)
		http.Error(w, "Failed to save config", http.StatusInternalServerError)
		return
	}

	// Regenerate and apply dnsmasq config
	if err := app.DnsmasqManager.WriteConfig(app.Config, paths.DnsmasqConf); err != nil {
		log.Printf("Failed to update dnsmasq config: %v", err)
		http.Error(w, "Failed to update dnsmasq config", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "updated"})
}

// GetConfigYamlHandler handles raw YAML config file retrieval
func (app *App) GetConfigYamlHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	paths := app.DataManager.GetPaths()

	// Read the raw config file
	yamlContent, err := os.ReadFile(paths.ConfigFile)
	if err != nil {
		if os.IsNotExist(err) {
			http.Error(w, "Configuration file not found", http.StatusNotFound)
			return
		}
		log.Printf("Failed to read config file: %v", err)
		http.Error(w, "Failed to read configuration file", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	w.Write(yamlContent)
}

// UpdateConfigYamlHandler handles raw YAML config file updates
func (app *App) UpdateConfigYamlHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Read the raw YAML content from request body
	yamlContent, err := io.ReadAll(r.Body)
	if err != nil {
		log.Printf("Failed to read request body: %v", err)
		http.Error(w, "Failed to read request body", http.StatusBadRequest)
		return
	}

	paths := app.DataManager.GetPaths()

	// Write the raw YAML content to file
	if err := os.WriteFile(paths.ConfigFile, yamlContent, 0644); err != nil {
		log.Printf("Failed to write config file: %v", err)
		http.Error(w, "Failed to write configuration file", http.StatusInternalServerError)
		return
	}

	// Try to reload the config to validate it and update the in-memory config
	newConfig, err := config.Load(paths.ConfigFile)
	if err != nil {
		log.Printf("Warning: Saved YAML config but failed to parse it: %v", err)
		// File was written but parsing failed - this is a validation warning
		w.Header().Set("Content-Type", "application/json")
		response := map[string]interface{}{
			"status":  "saved_with_warnings",
			"warning": "Configuration saved but contains validation errors: " + err.Error(),
		}
		json.NewEncoder(w).Encode(response)
		return
	}

	// Update in-memory config if parsing succeeded
	app.Config = newConfig

	// Try to regenerate dnsmasq config if the new config is valid
	if err := app.DnsmasqManager.WriteConfig(app.Config, paths.DnsmasqConf); err != nil {
		log.Printf("Warning: Failed to update dnsmasq config: %v", err)
		// Config was saved but dnsmasq update failed
		w.Header().Set("Content-Type", "application/json")
		response := map[string]interface{}{
			"status":  "saved_with_warnings",
			"warning": "Configuration saved but failed to update dnsmasq config: " + err.Error(),
		}
		json.NewEncoder(w).Encode(response)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "updated"})
}

// CORSMiddleware adds CORS headers to responses
func (app *App) CORSMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}
