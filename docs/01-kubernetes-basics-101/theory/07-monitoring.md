# 7. Monitoring & Observability

## Why Monitor?

Running containers is easy. Knowing **when something is wrong before your users notice** is the hard part.

The three pillars of observability:

| Pillar | What | Tool |
|--------|------|------|
| **Metrics** | Numbers over time (CPU, memory, request count) | Prometheus |
| **Logs** | Event records from applications | Loki, EFK stack |
| **Traces** | Request flow across services | Jaeger, Zipkin |

## Prometheus

The standard for Kubernetes monitoring. Pull-based: Prometheus **scrapes** metrics from endpoints.

```
┌──────────┐   scrapes   ┌──────────┐
│Prometheus│◄────────────│ App /    │
│          │             │ metrics  │
│  (TSDB)  │             └──────────┘
└────┬─────┘
     │ queries
     ▼
┌──────────┐
│ Grafana  │ ──► Dashboards & Alerts
└──────────┘
```

### How it works

1. Apps expose a `/metrics` endpoint in Prometheus format
2. Prometheus scrapes these endpoints on a schedule
3. Data is stored in a time-series database
4. Grafana visualizes it, PromQL queries it

### Metrics format

```
# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET", endpoint="/api/users", status="200"} 1234
http_requests_total{method="POST", endpoint="/api/users", status="201"} 56

# HELP http_request_duration_seconds Duration of HTTP requests
# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_bucket{le="0.1"} 900
http_request_duration_seconds_bucket{le="0.5"} 1100
http_request_duration_seconds_bucket{le="1.0"} 1190
```

### Key metrics to monitor

**Node level:**
- CPU usage, memory usage, disk I/O, network I/O

**Pod level:**
- CPU/memory requests vs actual usage
- Restart count (high = something is crashing)
- Pod status (Running, Pending, CrashLoopBackOff)

**Application level:**
- Request rate (requests/second)
- Error rate (5xx responses)
- Duration (latency percentiles: p50, p95, p99)
- Saturation (queue depth, thread pool usage)

This is the **RED method**: Rate, Errors, Duration.

## Grafana

Visualization platform. Connects to Prometheus (and many other data sources) to build dashboards.

Key features:
- Pre-built dashboards for K8s (import from grafana.com)
- Alerting (Slack, email, PagerDuty)
- Variables and templating
- Dashboard-as-code with JSON/YAML

## Built-in Kubernetes Monitoring

### kubectl top

```bash
# Requires metrics-server
minikube addons enable metrics-server

# Node resources
kubectl top nodes
# NAME       CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
# minikube   250m         12%    1024Mi          52%

# Pod resources
kubectl top pods
# NAME         CPU(cores)   MEMORY(bytes)
# web-abc123   5m           32Mi
# db-def456    100m         256Mi
```

### Probes - Health Checks

Tell Kubernetes how to check if your app is healthy:

```yaml
spec:
  containers:
  - name: app
    image: myapp
    # Is the app alive? If not, restart it.
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 10
      periodSeconds: 5

    # Is the app ready to receive traffic?
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 3

    # Has the app finished starting up?
    startupProbe:
      httpGet:
        path: /healthz
        port: 8080
      failureThreshold: 30
      periodSeconds: 10
```

| Probe | Purpose | Failure action |
|-------|---------|---------------|
| **Liveness** | Is it alive? | Restart container |
| **Readiness** | Can it serve traffic? | Remove from Service endpoints |
| **Startup** | Has it started? | Keep waiting (don't liveness-check yet) |

## Kubernetes Dashboard

A web UI for your cluster:

```bash
minikube addons enable dashboard
minikube dashboard
```

Good for beginners to visualize what's running. Not a replacement for proper monitoring.

## Logging

```bash
# View pod logs
kubectl logs <pod-name>
kubectl logs <pod-name> -f              # follow
kubectl logs <pod-name> -c <container>  # specific container
kubectl logs <pod-name> --previous      # previous (crashed) instance
kubectl logs -l app=web                 # all pods with label

# For production, ship logs to a centralized system:
# - EFK stack (Elasticsearch + Fluentd + Kibana)
# - Loki + Grafana (lighter, label-based)
# - Cloud: Azure Monitor, CloudWatch, Stackdriver
```

## The Monitoring Stack We'll Deploy in Lab 6

```
┌────────────────────────────────────────┐
│           kube-prometheus-stack        │
│                                        │
│  ┌────────────┐  ┌─────────┐  ┌───────┐│
│  │ Prometheus │  │ Grafana │  │Alert- ││
│  │ + node-    │  │         │  │manager││
│  │   exporter │  │         │  │       ││
│  └────────────┘  └─────────┘  └───────┘│
└────────────────────────────────────────┘
```

We'll use Helm to install the entire stack in one command.

---

**Next: [Real-World Patterns →](08-real-world.md)**
