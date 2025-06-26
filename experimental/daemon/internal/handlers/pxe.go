package handlers

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
)

// DownloadPXEAssetsHandler handles requests to download PXE boot assets
func (app *App) DownloadPXEAssetsHandler(w http.ResponseWriter, r *http.Request) {
	if app.Config == nil || app.Config.IsEmpty() {
		http.Error(w, "No configuration available. Please configure the system first.", http.StatusPreconditionFailed)
		return
	}

	if err := app.downloadTalosAssets(); err != nil {
		log.Printf("Failed to download PXE assets: %v", err)
		http.Error(w, "Failed to download PXE assets", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "downloaded"})
}

// downloadTalosAssets downloads Talos Linux PXE assets
func (app *App) downloadTalosAssets() error {
	// Get assets directory from data paths
	paths := app.DataManager.GetPaths()
	assetsDir := filepath.Join(paths.AssetsDir, "talos")
	
	log.Printf("Downloading Talos assets to: %s", assetsDir)
	if err := os.MkdirAll(filepath.Join(assetsDir, "amd64"), 0755); err != nil {
		return fmt.Errorf("creating assets directory: %w", err)
	}

	// Create Talos bare metal configuration (schematic format)
	bareMetalConfig := `customization:
  extraKernelArgs:
    - net.ifnames=0
  systemExtensions:
    officialExtensions:
      - siderolabs/gvisor
      - siderolabs/intel-ucode`

	// Create Talos schematic
	var buf bytes.Buffer
	buf.WriteString(bareMetalConfig)

	resp, err := http.Post("https://factory.talos.dev/schematics", "text/yaml", &buf)
	if err != nil {
		return fmt.Errorf("creating Talos schematic: %w", err)
	}
	defer resp.Body.Close()

	var schematic struct {
		ID string `json:"id"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&schematic); err != nil {
		return fmt.Errorf("decoding schematic response: %w", err)
	}

	log.Printf("Created Talos schematic with ID: %s", schematic.ID)

	// Download kernel
	kernelURL := fmt.Sprintf("https://pxe.factory.talos.dev/image/%s/%s/kernel-amd64",
		schematic.ID, app.Config.Cluster.Nodes.Talos.Version)
	if err := downloadFile(kernelURL, filepath.Join(assetsDir, "amd64", "vmlinuz")); err != nil {
		return fmt.Errorf("downloading kernel: %w", err)
	}

	// Download initramfs
	initramfsURL := fmt.Sprintf("https://pxe.factory.talos.dev/image/%s/%s/initramfs-amd64.xz",
		schematic.ID, app.Config.Cluster.Nodes.Talos.Version)
	if err := downloadFile(initramfsURL, filepath.Join(assetsDir, "amd64", "initramfs.xz")); err != nil {
		return fmt.Errorf("downloading initramfs: %w", err)
	}

	// Create boot.ipxe file
	bootScript := fmt.Sprintf(`#!ipxe
imgfree
kernel http://%s/amd64/vmlinuz talos.platform=metal console=tty0 init_on_alloc=1 slab_nomerge pti=on consoleblank=0 nvme_core.io_timeout=4294967295 printk.devkmsg=on ima_template=ima-ng ima_appraise=fix ima_hash=sha512 selinux=1 net.ifnames=0
initrd http://%s/amd64/initramfs.xz
boot
`, app.Config.Cloud.DNS.IP, app.Config.Cloud.DNS.IP)

	if err := os.WriteFile(filepath.Join(assetsDir, "boot.ipxe"), []byte(bootScript), 0644); err != nil {
		return fmt.Errorf("writing boot script: %w", err)
	}

	// Download iPXE bootloaders  
	tftpDir := filepath.Join(paths.AssetsDir, "tftp")
	if err := os.MkdirAll(tftpDir, 0755); err != nil {
		return fmt.Errorf("creating tftp directory: %w", err)
	}

	bootloaders := map[string]string{
		"http://boot.ipxe.org/ipxe.efi":           filepath.Join(tftpDir, "ipxe.efi"),
		"http://boot.ipxe.org/undionly.kpxe":      filepath.Join(tftpDir, "undionly.kpxe"),
		"http://boot.ipxe.org/arm64-efi/ipxe.efi": filepath.Join(tftpDir, "ipxe-arm64.efi"),
	}

	for url, path := range bootloaders {
		if err := downloadFile(url, path); err != nil {
			return fmt.Errorf("downloading %s: %w", url, err)
		}
	}

	log.Printf("Successfully downloaded PXE assets")
	return nil
}

// downloadFile downloads a file from a URL to a local path
func downloadFile(url, filepath string) error {
	resp, err := http.Get(url)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("bad status: %s", resp.Status)
	}

	out, err := os.Create(filepath)
	if err != nil {
		return err
	}
	defer out.Close()

	_, err = io.Copy(out, resp.Body)
	return err
}