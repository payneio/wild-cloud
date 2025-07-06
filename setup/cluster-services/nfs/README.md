# NFS Setup (Optional)

The infrastructure supports optional NFS (Network File System) for shared media storage across the cluster:

## Host Setup

First, set up the NFS server on your chosen host.

```bash
./setup-nfs-host.sh
```

## Cluster Integration

Add to your `config.yaml`:

```yaml
cloud:
  nfs:
    host: box-01
    mediaPath: /data/media
    storageCapacity: 250Gi
```

And now you can run the nfs cluster setup:

```bash
setup/setup-nfs-host.sh
```

## Features

- Automatic IP detection - Uses network IP even when hostname resolves to localhost
- Cluster-wide access - Any pod can mount the NFS share regardless of node placement
- Configurable capacity - Set PersistentVolume size via `NFS_STORAGE_CAPACITY`
- ReadWriteMany - Multiple pods can simultaneously access the same storage

## Usage

Applications can use NFS storage by setting `storageClassName: nfs` in their PVCs:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: media-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: nfs
  resources:
    requests:
      storage: 100Gi
```
