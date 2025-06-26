package config

import (
	"fmt"
	"os"
	"path/filepath"

	"gopkg.in/yaml.v3"
)

// Config represents the main configuration structure
type Config struct {
	Wildcloud struct {
		Repository       string   `yaml:"repository" json:"repository"`
		CurrentPhase     string   `yaml:"currentPhase" json:"currentPhase"`
		CompletedPhases  []string `yaml:"completedPhases" json:"completedPhases"`
	} `yaml:"wildcloud" json:"wildcloud"`
	Server struct {
		Port int    `yaml:"port" json:"port"`
		Host string `yaml:"host" json:"host"`
	} `yaml:"server" json:"server"`
	Cloud struct {
		Domain         string `yaml:"domain" json:"domain"`
		InternalDomain string `yaml:"internalDomain" json:"internalDomain"`
		DNS            struct {
			IP string `yaml:"ip" json:"ip"`
		} `yaml:"dns" json:"dns"`
		Router struct {
			IP string `yaml:"ip" json:"ip"`
		} `yaml:"router" json:"router"`
		DHCPRange string `yaml:"dhcpRange" json:"dhcpRange"`
		Dnsmasq   struct {
			Interface string `yaml:"interface" json:"interface"`
		} `yaml:"dnsmasq" json:"dnsmasq"`
	} `yaml:"cloud" json:"cloud"`
	Cluster struct {
		EndpointIP string `yaml:"endpointIp" json:"endpointIp"`
		Nodes      struct {
			Talos struct {
				Version string `yaml:"version" json:"version"`
			} `yaml:"talos" json:"talos"`
		} `yaml:"nodes" json:"nodes"`
	} `yaml:"cluster" json:"cluster"`
}

// Load loads configuration from the specified path
func Load(configPath string) (*Config, error) {
	data, err := os.ReadFile(configPath)
	if err != nil {
		return nil, fmt.Errorf("reading config file %s: %w", configPath, err)
	}

	config := &Config{}
	if err := yaml.Unmarshal(data, config); err != nil {
		return nil, fmt.Errorf("parsing config file: %w", err)
	}

	// Set defaults
	if config.Server.Port == 0 {
		config.Server.Port = 5055
	}
	if config.Server.Host == "" {
		config.Server.Host = "0.0.0.0"
	}

	return config, nil
}

// Save saves the configuration to the specified path
func Save(config *Config, configPath string) error {
	// Ensure the directory exists
	if err := os.MkdirAll(filepath.Dir(configPath), 0755); err != nil {
		return fmt.Errorf("creating config directory: %w", err)
	}

	data, err := yaml.Marshal(config)
	if err != nil {
		return fmt.Errorf("marshaling config: %w", err)
	}

	return os.WriteFile(configPath, data, 0644)
}

// IsEmpty checks if the configuration is empty or uninitialized
func (c *Config) IsEmpty() bool {
	if c == nil {
		return true
	}
	
	// Check if any essential fields are empty
	return c.Cloud.Domain == "" || 
		   c.Cloud.DNS.IP == "" ||
		   c.Cluster.Nodes.Talos.Version == ""
}