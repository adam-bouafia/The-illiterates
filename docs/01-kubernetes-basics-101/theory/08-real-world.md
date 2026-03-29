# 8. Real-World Patterns

## How Teams Actually Use Kubernetes

### GitOps

Store your K8s manifests in Git. A tool watches the repo and applies changes automatically.

```
Developer pushes code
       │
       ▼
CI builds new image ──► pushes to registry
       │
       ▼
Updates image tag in Git manifests repo
       │
       ▼
ArgoCD / Flux detects change ──► applies to cluster
```

**Tools:** ArgoCD, Flux

**Why:** Auditable history, easy rollback (just `git revert`), single source of truth.

### Helm - Package Manager for K8s

Instead of managing 10+ YAML files per app, Helm bundles them into **charts**.

```bash
# Install an app
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install my-redis bitnami/redis

# Install with custom values
helm install my-redis bitnami/redis \
  --set auth.password=mysecret \
  --set replica.replicaCount=3

# List installed releases
helm list

# Upgrade
helm upgrade my-redis bitnami/redis --set replica.replicaCount=5

# Rollback
helm rollback my-redis 1
```

A Helm chart is just templated YAML:

```yaml
# templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}
spec:
  replicas: {{ .Values.replicaCount }}
  template:
    spec:
      containers:
      - name: app
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
```

```yaml
# values.yaml
replicaCount: 3
image:
  repository: nginx
  tag: "1.25"
```

### Horizontal Pod Autoscaler (HPA)

Automatically scale pods based on CPU/memory or custom metrics.

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

When average CPU > 70% → scale up. When it drops → scale down.

### Resource Quotas

Limit resources per namespace to prevent one team from hogging the cluster.

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-quota
  namespace: team-a
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    pods: "20"
```

### RBAC - Role-Based Access Control

Control who can do what in the cluster.

```yaml
# Role: what actions are allowed
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: dev
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]

---
# RoleBinding: who gets the role
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: dev
subjects:
- kind: User
  name: "adam"
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

## Common Deployment Patterns

### Blue-Green Deployment

Run two identical environments. Switch traffic instantly.

```
Traffic ──► Service (selector: version=blue)
                │
        ┌───────┴───────┐
        ▼               ▼
   Blue (v1)       Green (v2)  ← deploy here, test

# Switch: update service selector to version=green
```

### Canary Deployment

Route a small % of traffic to the new version first.

```
Traffic ──► Service
              │
        ┌─────┴─────┐
        ▼           ▼
   v1 (90%)     v2 (10%)  ← monitor errors
```

Implementation: run 9 replicas of v1 and 1 of v2, all with the same label.

### Sidecar Pattern

Add a helper container to your pod (logging, proxy, auth):

```yaml
spec:
  containers:
  - name: app
    image: myapp
  - name: log-shipper        # sidecar
    image: fluentd
    volumeMounts:
    - name: logs
      mountPath: /var/log
```

## Production Checklist

Before deploying to production, ensure:

- [ ] Resource requests and limits set for all containers
- [ ] Liveness and readiness probes configured
- [ ] Pod Disruption Budgets defined
- [ ] Network Policies in place
- [ ] Secrets not hardcoded (use external secret manager)
- [ ] Image tags pinned (never use `latest` in prod)
- [ ] RBAC configured (principle of least privilege)
- [ ] Monitoring and alerting set up
- [ ] Backup strategy for persistent data
- [ ] Resource quotas per namespace

---

**This concludes the theory section. Head to the [Labs](../labs/lab-00-setup.md) to get hands-on!**
