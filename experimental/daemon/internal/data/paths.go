package data

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
)

// Paths represents the data directory paths configuration
type Paths struct {
	ConfigFile  string
	DataDir     string
	LogsDir     string
	AssetsDir   string
	DnsmasqConf string
}

// Manager handles data directory management
type Manager struct {
	dataDir string
	isDev   bool
}

// NewManager creates a new data manager
func NewManager() *Manager {
	return &Manager{}
}

// Initialize sets up the data directory structure
func (m *Manager) Initialize() error {
	// Detect environment: development vs production
	m.isDev = m.isDevelopmentMode()
	
	var dataDir string
	if m.isDev {
		// Development mode: use .wildcloud in current directory
		cwd, err := os.Getwd()
		if err != nil {
			return fmt.Errorf("failed to get current directory: %w", err)
		}
		dataDir = filepath.Join(cwd, ".wildcloud")
		log.Printf("Running in development mode, using data directory: %s", dataDir)
	} else {
		// Production mode: use standard Linux directories
		dataDir = "/var/lib/wild-cloud-central"
		log.Printf("Running in production mode, using data directory: %s", dataDir)
	}
	
	m.dataDir = dataDir
	
	// Create directory structure
	paths := m.GetPaths()
	
	// Create all necessary directories
	for _, dir := range []string{paths.DataDir, paths.LogsDir, paths.AssetsDir} {
		if err := os.MkdirAll(dir, 0755); err != nil {
			return fmt.Errorf("failed to create directory %s: %w", dir, err)
		}
	}
	
	log.Printf("Data directory structure initialized at: %s", dataDir)
	return nil
}

// isDevelopmentMode detects if we're running in development mode
func (m *Manager) isDevelopmentMode() bool {
	// Check multiple indicators for development mode
	
	// 1. Check if GO_ENV is set to development
	if env := os.Getenv("GO_ENV"); env == "development" {
		return true
	}
	
	// 2. Check if running as systemd service (has INVOCATION_ID)
	if os.Getenv("INVOCATION_ID") != "" {
		return false // Running under systemd
	}
	
	// 3. Check if running from a typical development location
	if exe, err := os.Executable(); err == nil {
		// If executable is in current directory or contains "wild-central" without being in /usr/bin
		if strings.Contains(exe, "/usr/bin") || strings.Contains(exe, "/usr/local/bin") {
			return false
		}
		if filepath.Base(exe) == "wild-central" && !strings.HasPrefix(exe, "/") {
			return true
		}
	}
	
	// 4. Check if we can write to /var/lib (if not, probably development)
	if _, err := os.Stat("/var/lib"); err != nil {
		return true
	}
	
	// 5. Default to development if uncertain
	return true
}

// GetPaths returns the appropriate paths for the current environment
func (m *Manager) GetPaths() Paths {
	if m.isDev {
		return Paths{
			ConfigFile:  filepath.Join(m.dataDir, "config.yaml"),
			DataDir:     m.dataDir,
			LogsDir:     filepath.Join(m.dataDir, "logs"),
			AssetsDir:   filepath.Join(m.dataDir, "assets"),
			DnsmasqConf: filepath.Join(m.dataDir, "dnsmasq.conf"),
		}
	} else {
		return Paths{
			ConfigFile:  "/etc/wild-cloud-central/config.yaml",
			DataDir:     m.dataDir,
			LogsDir:     "/var/log/wild-cloud-central",
			AssetsDir:   "/var/www/html/wild-central",
			DnsmasqConf: "/etc/dnsmasq.conf",
		}
	}
}

// GetDataDir returns the current data directory
func (m *Manager) GetDataDir() string {
	return m.dataDir
}

// IsDevelopment returns true if running in development mode
func (m *Manager) IsDevelopment() bool {
	return m.isDev
}