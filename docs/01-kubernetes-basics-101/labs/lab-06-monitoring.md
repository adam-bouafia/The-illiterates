# Lab 6: Monitoring with Prometheus & Grafana

**Time: ~25 minutes**

## Objective

Deploy a full monitoring stack (Prometheus + Grafana) and monitor your cluster.

## Exercise 1: Install kube-prometheus-stack via Helm

```bash
# Add the Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install the full stack
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.retention=2h \
  --set grafana.adminPassword=illiterates

# Wait for everything to come up (this takes a few minutes)
kubectl get pods -n monitoring -w
# Wait until all pods show Running/Completed
```

What just got deployed:
- **Prometheus** - metrics collection and storage
- **Grafana** - dashboards and visualization
- **Alertmanager** - alert routing
- **node-exporter** - host-level metrics (CPU, memory, disk)
- **kube-state-metrics** - Kubernetes object metrics

## Exercise 2: Access Grafana

```bash
# Port-forward Grafana to your laptop
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80
```

Open http://localhost:3000 in your browser.

- **Username:** `admin`
- **Password:** `illiterates`

### Explore Pre-built Dashboards

Go to **Dashboards → Browse**. You'll find pre-installed dashboards:

1. **Kubernetes / Compute Resources / Cluster** - Cluster-wide CPU and memory
2. **Kubernetes / Compute Resources / Namespace (Pods)** - Per-namespace breakdown
3. **Kubernetes / Compute Resources / Pod** - Individual pod metrics
4. **Node Exporter / Nodes** - Host-level metrics

Explore each one. This is what production monitoring looks like.

## Exercise 3: Access Prometheus

```bash
# In a new terminal:
kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090
```

Open http://localhost:9090.

### Try PromQL Queries

In the Prometheus UI, enter these queries:

```promql
# Total pods per namespace
count by (namespace) (kube_pod_info)

# CPU usage per node
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage percentage
(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100

# Pod restart count
kube_pod_container_status_restarts_total

# Container CPU usage
rate(container_cpu_usage_seconds_total{namespace="default"}[5m])

# Container memory usage in MB
container_memory_working_set_bytes{namespace="default"} / 1024 / 1024
```

## Exercise 4: Deploy an App and Monitor It

Create a deployment to observe:

```bash
# Deploy a web app
kubectl create deployment monitored-app --image=nginx:1.25 --replicas=3
kubectl expose deployment monitored-app --port=80

# Generate some load
kubectl run load-gen --rm -it --image=busybox -- sh -c "while true; do wget -qO- http://monitored-app > /dev/null; done"
# Let it run for ~1 minute, then Ctrl+C
```

Now go to Grafana:

1. Navigate to **Dashboards → Kubernetes / Compute Resources / Namespace (Pods)**
2. Select namespace: `default`
3. You should see CPU and memory usage for your `monitored-app` pods
4. Try the **Pod** dashboard and select one of the monitored-app pods

## Exercise 5: kubectl top

```bash
# Make sure metrics-server is running (should be enabled from Lab 0)
minikube addons enable metrics-server

# If the addon fails, install manually:
# kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Verify metrics-server is ready
kubectl get pods -n kube-system | grep metrics-server

# Wait a minute for metrics to populate, then:
kubectl top nodes
kubectl top pods
kubectl top pods -n monitoring
kubectl top pods --sort-by=memory
```

## Exercise 6: Create a Custom Grafana Dashboard

In Grafana:

1. Click **+ → New Dashboard → Add Visualization**
2. Select **Prometheus** as data source
3. Enter query: `rate(container_cpu_usage_seconds_total{namespace="default"}[5m])`
4. Set title: "Default Namespace CPU Usage"
5. Click **Apply**
6. Add another panel with: `container_memory_working_set_bytes{namespace="default"} / 1024 / 1024`
7. Set title: "Default Namespace Memory (MB)"
8. Save the dashboard as "Workshop Monitoring"

## Exercise 7: Alerts (Bonus)

Check existing alert rules:

```bash
kubectl get prometheusrules -n monitoring
```

View them in Prometheus UI → **Alerts** tab. You'll see pre-configured alerts like:

- `KubePodCrashLooping` - pod restarting too often
- `KubePodNotReady` - pod stuck in non-ready state
- `NodeFilesystemSpaceFillingUp` - disk running out

These are production-grade alerts that real teams use.

## Cleanup

```bash
kubectl delete deployment monitored-app
kubectl delete svc monitored-app

# Keep the monitoring stack for Lab 7, or remove it:
# helm uninstall monitoring -n monitoring
# kubectl delete namespace monitoring
```

## Key Takeaways

1. **kube-prometheus-stack** gives you production-grade monitoring in one Helm install
2. **Prometheus** scrapes and stores metrics; query with **PromQL**
3. **Grafana** visualizes metrics with pre-built K8s dashboards
4. `kubectl top` for quick resource checks; Grafana for deep analysis
5. Monitor the **RED metrics**: Rate, Errors, Duration
6. Pre-configured alerts catch common issues automatically

---

**Next: [Lab 7: Deploy a Full App →](lab-07-full-app.md)**
