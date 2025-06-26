package handlers

import (
	"encoding/json"
	"log"
	"net/http"
)

// GetDnsmasqConfigHandler handles requests to view the dnsmasq configuration
func (app *App) GetDnsmasqConfigHandler(w http.ResponseWriter, r *http.Request) {
	if app.Config == nil || app.Config.IsEmpty() {
		http.Error(w, "No configuration available. Please configure the system first.", http.StatusPreconditionFailed)
		return
	}
	
	config := app.DnsmasqManager.Generate(app.Config)
	w.Header().Set("Content-Type", "text/plain")
	w.Write([]byte(config))
}

// RestartDnsmasqHandler handles requests to restart the dnsmasq service
func (app *App) RestartDnsmasqHandler(w http.ResponseWriter, r *http.Request) {
	if app.Config == nil || app.Config.IsEmpty() {
		http.Error(w, "No configuration available. Please configure the system first.", http.StatusPreconditionFailed)
		return
	}

	// Update dnsmasq config first
	paths := app.DataManager.GetPaths()
	if err := app.DnsmasqManager.WriteConfig(app.Config, paths.DnsmasqConf); err != nil {
		log.Printf("Failed to update dnsmasq config: %v", err)
		http.Error(w, "Failed to update dnsmasq config", http.StatusInternalServerError)
		return
	}

	// Restart dnsmasq service
	if err := app.DnsmasqManager.RestartService(); err != nil {
		log.Printf("Failed to restart dnsmasq: %v", err)
		http.Error(w, "Failed to restart dnsmasq service", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "restarted"})
}