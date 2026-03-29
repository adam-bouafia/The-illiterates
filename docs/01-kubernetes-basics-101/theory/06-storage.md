# 6. Storage

## The Problem

Containers are **ephemeral** - when a pod dies, all data inside it is lost. Databases, file uploads, logs - gone. Kubernetes storage objects let you persist data beyond pod lifecycle.

## Volumes

A directory accessible to containers in a pod. Many types exist:

### emptyDir

Temporary storage that exists as long as the pod exists. Good for scratch space or sharing files between containers in the same pod.

```yaml
spec:
  containers:
  - name: app
    image: myapp
    volumeMounts:
    - name: cache
      mountPath: /tmp/cache
  - name: sidecar
    image: log-processor
    volumeMounts:
    - name: cache
      mountPath: /data
  volumes:
  - name: cache
    emptyDir: {}
```

### hostPath

Mounts a directory from the **host node's filesystem**. Use with caution - ties your pod to a specific node.

```yaml
volumes:
- name: host-data
  hostPath:
    path: /var/log/containers
    type: Directory
```

## Persistent Volumes (PV) & Persistent Volume Claims (PVC)

The proper way to handle storage in Kubernetes.

```
Admin creates          User requests          Pod uses
┌────────────┐        ┌──────────────┐       ┌──────────┐
│ Persistent │◄───────│  Persistent  │◄──────│   Pod    │
│   Volume   │ binds  │ Volume Claim │ mounts│          │
│   (PV)     │        │   (PVC)      │       │          │
└────────────┘        └──────────────┘       └──────────┘
  100Gi NFS             "I need 10Gi"         /data
```

### PersistentVolume (PV)

A piece of storage provisioned by an admin or dynamically.

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /mnt/data
```

### PersistentVolumeClaim (PVC)

A user's request for storage.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```

### Using PVC in a Pod

```yaml
spec:
  containers:
  - name: db
    image: postgres:16
    volumeMounts:
    - name: db-storage
      mountPath: /var/lib/postgresql/data
  volumes:
  - name: db-storage
    persistentVolumeClaim:
      claimName: my-pvc
```

## Access Modes

| Mode | Short | Description |
|------|-------|-------------|
| ReadWriteOnce | RWO | One node can mount read-write |
| ReadOnlyMany | ROX | Many nodes can mount read-only |
| ReadWriteMany | RWX | Many nodes can mount read-write |

## Storage Classes

Define **types of storage** with different performance characteristics. Enable **dynamic provisioning** - no need to manually create PVs.

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp3
  iopsPerGB: "50"
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
```

Use it in a PVC:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: fast-storage
spec:
  storageClassName: fast-ssd
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
```

Minikube has a default storage class (`standard`) that provisions hostPath volumes automatically.

```bash
kubectl get storageclass
# NAME                 PROVISIONER                RECLAIMPOLICY
# standard (default)   k8s.io/minikube-hostpath   Delete
```

## Reclaim Policies

What happens when a PVC is deleted:

| Policy | Behavior |
|--------|----------|
| **Retain** | PV is kept, must be manually cleaned |
| **Delete** | PV and underlying storage are deleted |
| **Recycle** | Deprecated. Was `rm -rf /volume/*` |

---

**Next: [Monitoring & Observability →](07-monitoring.md)**
