# 4. Networking & Services

## The Networking Problem

Pods get IP addresses, but those IPs are **ephemeral** - when a pod dies and restarts, it gets a new IP. You can't hardcode pod IPs.

**Services** solve this: a stable endpoint that routes traffic to the right pods.

## Kubernetes Networking Model

Three rules that every K8s network implementation must follow:

1. **Every pod gets its own IP** - no NAT between pods
2. **All pods can talk to all other pods** - across nodes, without NAT
3. **Agents on a node can talk to all pods on that node**

```
┌──────────── Cluster Network ─────────────┐
│                                          │
│  Node 1              Node 2              │
│  ┌─────────┐         ┌─────────┐         │
│  │Pod      │         │Pod      │         │
│  │10.244.1.│◄───────►│10.244.2.│         │
│  │5        │  Direct │3        │         │
│  └─────────┘         └─────────┘         │
│                                          │
└──────────────────────────────────────────┘
```

## Services

### ClusterIP (default)

Internal-only access. Other pods can reach it, but nothing outside the cluster.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-svc
spec:
  type: ClusterIP
  selector:
    app: backend        # routes to pods with label app=backend
  ports:
  - port: 80            # service port
    targetPort: 8080     # container port
```

```bash
# Other pods can access it via:
curl http://backend-svc              # same namespace
curl http://backend-svc.default      # cross-namespace (namespace = default)
curl http://backend-svc.default.svc.cluster.local  # full FQDN
```

### NodePort

Exposes the service on a **static port on every node**. Accessible from outside the cluster.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-svc
spec:
  type: NodePort
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080      # accessible at <NodeIP>:30080
```

Port range: 30000-32767.

### LoadBalancer

Creates an **external load balancer** (in cloud environments). On local clusters (minikube), use `minikube tunnel` to simulate.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: public-web
spec:
  type: LoadBalancer
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 8080
```

### Service Types Summary

```
                    ClusterIP    NodePort    LoadBalancer
Internal access       ✓            ✓            ✓
External access       ✗            ✓            ✓
Load balancing        ✓            ✓            ✓
Fixed external IP     ✗            ✗            ✓
Cloud required        ✗            ✗            ✓
```

## DNS in Kubernetes

Every Service gets a DNS entry automatically:

```
<service-name>.<namespace>.svc.cluster.local
```

Examples:
```bash
# Service "redis" in namespace "cache"
redis.cache.svc.cluster.local

# Short form (same namespace)
redis

# Short form (cross-namespace)
redis.cache
```

Pods also get DNS entries:
```
<pod-ip-dashed>.<namespace>.pod.cluster.local
# Example: 10-244-1-5.default.pod.cluster.local
```

## Ingress

A single entry point for routing **HTTP/HTTPS traffic** to multiple services based on URL path or hostname.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: myapp.local
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-svc
            port:
              number: 80
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-svc
            port:
              number: 80
```

```
                    ┌── /api ──► api-svc ──► api pods
Internet ──► Ingress│
                    └── /    ──► frontend-svc ──► frontend pods
```

**Requires an Ingress Controller** (e.g., NGINX, Traefik). On minikube:
```bash
minikube addons enable ingress
```

## Network Policies

Firewall rules for pod-to-pod traffic. By default, all pods can talk to all pods. Network policies restrict this.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-only
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - port: 8080
```

This says: "Only pods with label `app=frontend` can reach `app=backend` on port 8080."

---

**Next: [Configuration & Secrets →](05-configuration.md)**
