# Lab 5: Persistent Storage

**Time: ~15 minutes**

## Objective

Understand ephemeral vs persistent storage, create PVCs, and survive pod restarts.

## Exercise 1: Ephemeral Storage (The Problem)

```bash
# Create a pod and write data
kubectl run temp-pod --image=busybox -- sh -c "echo 'important data' > /data.txt && sleep 3600"

# Verify data exists
kubectl exec temp-pod -- cat /data.txt
# important data

# Delete the pod
kubectl delete pod temp-pod

# Recreate it
kubectl run temp-pod --image=busybox -- sh -c "cat /data.txt 2>/dev/null || echo 'DATA IS GONE' && sleep 3600"

kubectl logs temp-pod
# DATA IS GONE
```

Data is lost. That's why we need persistent storage.

## Exercise 2: PersistentVolumeClaim

Minikube has a default StorageClass that auto-provisions volumes.

```bash
# Check available storage classes
kubectl get storageclass
# NAME                 PROVISIONER                RECLAIMPOLICY
# standard (default)   k8s.io/minikube-hostpath   Delete
```

Create `pvc.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-data
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

```bash
kubectl apply -f pvc.yaml

kubectl get pvc
# NAME      STATUS   VOLUME                                     CAPACITY   ACCESS MODES
# my-data   Bound    pvc-abc12345-...                            1Gi        RWO

kubectl get pv
# The PV was auto-created by the storage class
```

## Exercise 3: Use PVC in a Pod

Create `pvc-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: storage-test
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "echo 'persistent data - written at '$(date) > /data/hello.txt && sleep 3600"]
    volumeMounts:
    - name: my-storage
      mountPath: /data
  volumes:
  - name: my-storage
    persistentVolumeClaim:
      claimName: my-data
  restartPolicy: Never
```

```bash
kubectl apply -f pvc-pod.yaml

# Verify data was written
kubectl exec storage-test -- cat /data/hello.txt
# persistent data - written at Sat Mar 29 14:30:00 UTC 2026
```

## Exercise 4: Data Survives Pod Deletion

```bash
# Delete the pod
kubectl delete pod storage-test

# Create a new pod using the SAME PVC
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: storage-test-2
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "cat /data/hello.txt && sleep 3600"]
    volumeMounts:
    - name: my-storage
      mountPath: /data
  volumes:
  - name: my-storage
    persistentVolumeClaim:
      claimName: my-data
  restartPolicy: Never
EOF

kubectl logs storage-test-2
# persistent data - written at Sat Mar 29 14:30:00 UTC 2026
# DATA SURVIVED!
```

## Exercise 5: PostgreSQL with Persistent Storage

A real-world example. Create `postgres.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-data
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:16
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_PASSWORD
          value: "labpassword"
        - name: POSTGRES_DB
          value: "workshop"
        volumeMounts:
        - name: pg-data
          mountPath: /var/lib/postgresql/data
          subPath: pgdata
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
      volumes:
      - name: pg-data
        persistentVolumeClaim:
          claimName: postgres-data
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
```

```bash
kubectl apply -f postgres.yaml

# Wait for it to be ready
kubectl get pods -l app=postgres -w
# Wait for STATUS: Running

# Connect and create data
kubectl exec -it $(kubectl get pod -l app=postgres -o jsonpath='{.items[0].metadata.name}') -- psql -U postgres -d workshop -c "
CREATE TABLE workshop_attendees (name TEXT);
INSERT INTO workshop_attendees VALUES ('Adam'), ('The Illiterates');
SELECT * FROM workshop_attendees;
"

# Delete the pod (deployment will recreate it)
kubectl delete pod -l app=postgres

# Wait for new pod
kubectl get pods -l app=postgres -w

# Check data survived
kubectl exec -it $(kubectl get pod -l app=postgres -o jsonpath='{.items[0].metadata.name}') -- psql -U postgres -d workshop -c "SELECT * FROM workshop_attendees;"
#  name
# -------------------
#  Adam
#  The Illiterates
```

## Cleanup

```bash
kubectl delete deployment postgres
kubectl delete svc postgres
kubectl delete pod storage-test-2 temp-pod 2>/dev/null
kubectl delete pvc my-data postgres-data
rm -f pvc.yaml pvc-pod.yaml postgres.yaml
```

## Key Takeaways

1. Container storage is **ephemeral** - data dies with the pod
2. **PVC** = your request for storage; **PV** = the actual storage
3. Dynamic provisioning (via StorageClass) creates PVs automatically
4. Data persists across pod restarts when using PVCs
5. Always use `subPath` for databases to avoid permission issues
6. In production, use proper storage backends (cloud disks, NFS, Ceph)

---

**Next: [Lab 6: Monitoring with Prometheus & Grafana →](lab-06-monitoring.md)**
