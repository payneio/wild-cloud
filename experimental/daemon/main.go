package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/gorilla/mux"

	"wild-cloud-central/internal/config"
	"wild-cloud-central/internal/handlers"
)

func main() {
	// Create application instance
	app := handlers.NewApp()

	// Initialize data directory
	if err := app.DataManager.Initialize(); err != nil {
		log.Fatalf("Failed to initialize data directory: %v", err)
	}

	// Load configuration if it exists
	paths := app.DataManager.GetPaths()
	if cfg, err := config.Load(paths.ConfigFile); err != nil {
		log.Printf("No configuration found, starting with empty config: %v", err)
	} else {
		app.Config = cfg
		log.Printf("Configuration loaded successfully")
	}

	// Set up HTTP router
	router := mux.NewRouter()
	setupRoutes(app, router)

	// Use default server settings if config is empty
	host := "0.0.0.0"
	port := 5055
	if app.Config != nil && app.Config.Server.Host != "" {
		host = app.Config.Server.Host
	}
	if app.Config != nil && app.Config.Server.Port != 0 {
		port = app.Config.Server.Port
	}

	addr := fmt.Sprintf("%s:%d", host, port)
	log.Printf("Starting wild-cloud-central server on %s", addr)

	if err := http.ListenAndServe(addr, router); err != nil {
		log.Fatal("Server failed to start:", err)
	}
}

func setupRoutes(app *handlers.App, router *mux.Router) {
	// Add CORS middleware
	router.Use(app.CORSMiddleware)
	
	// API v1 routes
	router.HandleFunc("/api/v1/health", app.HealthHandler).Methods("GET")
	router.HandleFunc("/api/v1/config", app.GetConfigHandler).Methods("GET")
	router.HandleFunc("/api/v1/config", app.UpdateConfigHandler).Methods("PUT")
	router.HandleFunc("/api/v1/config", app.CreateConfigHandler).Methods("POST")
	router.HandleFunc("/api/v1/config/yaml", app.GetConfigYamlHandler).Methods("GET")
	router.HandleFunc("/api/v1/config/yaml", app.UpdateConfigYamlHandler).Methods("PUT")
	router.HandleFunc("/api/v1/dnsmasq/config", app.GetDnsmasqConfigHandler).Methods("GET")
	router.HandleFunc("/api/v1/dnsmasq/restart", app.RestartDnsmasqHandler).Methods("POST")
	router.HandleFunc("/api/v1/pxe/assets", app.DownloadPXEAssetsHandler).Methods("POST")
	
	// UI-specific endpoints
	router.HandleFunc("/api/status", app.StatusHandler).Methods("GET")

	// Serve static files
	router.PathPrefix("/").Handler(http.FileServer(http.Dir("./static/")))
}