# 3. Core Objects

Everything in Kubernetes is an **object** - a record of intent stored in etcd. You declare what you want, K8s makes it happen.

## Pods

The **smallest deployable unit**. A pod is one or more containers that share:

- Network namespace (same IP, can talk via `localhost`)
- Storage volumes
- Lifecycle

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
  labels:
    app: web
    env: dev
spec:
  containers:
  - name: app
    image: nginx:1.25
    ports:
    - containerPort: 80
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
```

**Key facts:**

- Pods are **ephemeral** - they can be killed and recreated at any time
- Never create pods directly in production - use Deployments
- Each pod gets its own IP address (cluster-internal)
- Labels are how K8s organizes and selects pods

### Resource Requests vs Limits

| | Request | Limit |
|--|---------|-------|
| What | Minimum guaranteed | Maximum allowed |
| Scheduling | Used to find a node | Not considered |
| Enforcement | Soft | Hard (OOMKill if exceeded) |

```
CPU: measured in millicores (1000m = 1 core)
Memory: measured in Mi/Gi (mebibytes/gibibytes)
```

## Deployments

Manages a set of identical pods. This is what you use 99% of the time.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1          # 1 extra pod during update
      maxUnavailable: 0     # never go below 3
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: app
        image: myapp:v2
        ports:
        - containerPort: 8080
```

**What Deployments give you:**

- **Scaling**: Change `replicas` → K8s adds/removes pods
- **Rolling updates**: Change the image → K8s gradually replaces pods
- **Rollback**: `kubectl rollout undo deployment/web-app`
- **Self-healing**: Pod dies → Deployment recreates it

### Rolling Update Visualized

```
v1  v1  v1          ← Current state (3 replicas of v1)
v1  v1  v1  v2      ← maxSurge=1: start 1 new v2 pod
v1  v1  v2          ← v2 is healthy, terminate 1 v1
v1  v1  v2  v2      ← start another v2
v1  v2  v2          ← terminate another v1
v1  v2  v2  v2      ← start last v2
v2  v2  v2          ← done, all v2
```

## ReplicaSets

You rarely interact with these directly. A Deployment creates ReplicaSets under the hood.

```bash
kubectl get rs
# NAME                  DESIRED   CURRENT   READY
# web-app-7d9c456f8d    3         3         3
```

Each time you update a Deployment, it creates a new ReplicaSet and scales down the old one. This is how rollbacks work - K8s just scales up the old ReplicaSet.

## Namespaces

Virtual clusters within a cluster. Used for isolation and organization.

```bash
# Default namespaces
kubectl get namespaces
# NAME              STATUS   AGE
# default           Active   1d    ← your stuff goes here by default
# kube-system       Active   1d    ← K8s internal components
# kube-public       Active   1d    ← publicly readable
# kube-node-lease   Active   1d    ← node heartbeats

# Create a namespace
kubectl create namespace staging

# Deploy to a specific namespace
kubectl apply -f deployment.yaml -n staging

# Set default namespace
kubectl config set-context --current --namespace=staging
```

**When to use namespaces:**

- Separate environments (dev, staging, prod) on same cluster
- Team isolation
- Resource quotas per namespace

## DaemonSets

Ensures a pod runs on **every node** (or selected nodes). Used for:

- Log collectors (Fluentd, Filebeat)
- Monitoring agents (node-exporter)
- Network plugins (Calico, Cilium)

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: log-collector
spec:
  selector:
    matchLabels:
      app: log-collector
  template:
    metadata:
      labels:
        app: log-collector
    spec:
      containers:
      - name: fluentd
        image: fluentd:latest
```

## StatefulSets

Like Deployments but for **stateful apps** (databases, message queues). Gives you:

- Stable, unique network identifiers (`pod-0`, `pod-1`, `pod-2`)
- Ordered deployment and scaling
- Persistent storage per pod

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: "postgres"
  replicas: 3
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
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
```

## Jobs & CronJobs

**Job**: Run a task to completion.

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: db-migration
spec:
  template:
    spec:
      containers:
      - name: migrate
        image: myapp:latest
        command: ["python", "manage.py", "migrate"]
      restartPolicy: Never
  backoffLimit: 3
```

**CronJob**: Run jobs on a schedule.

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: nightly-backup
spec:
  schedule: "0 2 * * *"  # 2 AM daily
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: backup-tool:latest
          restartPolicy: OnFailure
```

## Quick Reference

```bash
# Pods
kubectl get pods                     # list pods
kubectl describe pod <name>          # detailed info
kubectl logs <pod-name>              # view logs
kubectl logs <pod-name> -f           # follow logs
kubectl exec -it <pod-name> -- bash  # shell into pod
kubectl delete pod <name>            # delete pod

# Deployments
kubectl get deployments
kubectl scale deployment <name> --replicas=5
kubectl rollout status deployment/<name>
kubectl rollout history deployment/<name>
kubectl rollout undo deployment/<name>

# Namespaces
kubectl get ns
kubectl get pods -n <namespace>
kubectl get pods --all-namespaces    # or -A
```

---

**Next: [Networking & Services →](04-networking.md)**
