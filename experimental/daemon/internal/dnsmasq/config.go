package dnsmasq

import (
	"fmt"
	"log"
	"os"
	"os/exec"

	"wild-cloud-central/internal/config"
)

// ConfigGenerator handles dnsmasq configuration generation
type ConfigGenerator struct{}

// NewConfigGenerator creates a new dnsmasq config generator
func NewConfigGenerator() *ConfigGenerator {
	return &ConfigGenerator{}
}

// Generate creates a dnsmasq configuration from the app config
func (g *ConfigGenerator) Generate(cfg *config.Config) string {
	template := `# Configuration file for dnsmasq.

# Basic Settings
interface=%s
listen-address=%s
domain-needed
bogus-priv
no-resolv

# DNS Local Resolution - Central server handles these domains authoritatively
local=/%s/
address=/%s/%s
local=/%s/
address=/%s/%s
server=1.1.1.1
server=8.8.8.8

# --- DHCP Settings ---
dhcp-range=%s,12h
dhcp-option=3,%s
dhcp-option=6,%s

# --- PXE Booting ---
enable-tftp
tftp-root=/var/ftpd

dhcp-match=set:efi-x86_64,option:client-arch,7
dhcp-boot=tag:efi-x86_64,ipxe.efi
dhcp-boot=tag:!efi-x86_64,undionly.kpxe

dhcp-match=set:efi-arm64,option:client-arch,11
dhcp-boot=tag:efi-arm64,ipxe-arm64.efi

dhcp-userclass=set:ipxe,iPXE
dhcp-boot=tag:ipxe,http://%s/boot.ipxe

log-queries
log-dhcp
`

	return fmt.Sprintf(template,
		cfg.Cloud.Dnsmasq.Interface,
		cfg.Cloud.DNS.IP,
		cfg.Cloud.Domain,
		cfg.Cloud.Domain,
		cfg.Cluster.EndpointIP,
		cfg.Cloud.InternalDomain,
		cfg.Cloud.InternalDomain,
		cfg.Cluster.EndpointIP,
		cfg.Cloud.DHCPRange,
		cfg.Cloud.Router.IP,
		cfg.Cloud.DNS.IP,
		cfg.Cloud.DNS.IP,
	)
}

// WriteConfig writes the dnsmasq configuration to the specified path
func (g *ConfigGenerator) WriteConfig(cfg *config.Config, configPath string) error {
	configContent := g.Generate(cfg)

	log.Printf("Writing dnsmasq config to: %s", configPath)
	if err := os.WriteFile(configPath, []byte(configContent), 0644); err != nil {
		return fmt.Errorf("writing dnsmasq config: %w", err)
	}

	return nil
}

// RestartService restarts the dnsmasq service
func (g *ConfigGenerator) RestartService() error {
	cmd := exec.Command("sudo", "/usr/bin/systemctl", "restart", "dnsmasq.service")
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to restart dnsmasq: %w", err)
	}
	return nil
}