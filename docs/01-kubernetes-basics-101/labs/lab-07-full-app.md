# Lab 7: Deploy a Full Application

**Time: ~25 minutes**

## Objective

Deploy a complete multi-tier application (frontend + backend + database) with proper K8s patterns: namespaces, configmaps, secrets, services, persistent storage, and health checks.

## The Application

We'll deploy a simple guestbook app:

```
Browser → Ingress → Frontend (nginx) → Backend API → PostgreSQL
```

## Step 1: Create the Namespace

```bash
kubectl create namespace guestbook
```

## Step 2: Database Layer

Create `01-database.yaml`:

```yaml
# Secret for DB credentials
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
  namespace: guestbook
type: Opaque
data:
  POSTGRES_USER: Z3Vlc3Rib29r        # guestbook
  POSTGRES_PASSWORD: V29ya3Nob3AyMDI2  # Workshop2026
  POSTGRES_DB: Z3Vlc3Rib29r          # guestbook

---
# Persistent storage for DB
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: guestbook
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi

---
# PostgreSQL Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: guestbook
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
      tier: database
  template:
    metadata:
      labels:
        app: postgres
        tier: database
    spec:
      containers:
      - name: postgres
        image: postgres:16-alpine
        ports:
        - containerPort: 5432
        envFrom:
        - secretRef:
            name: postgres-secret
        volumeMounts:
        - name: pg-data
          mountPath: /var/lib/postgresql/data
          subPath: pgdata
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "256Mi"
        readinessProbe:
          exec:
            command: ["pg_isready", "-U", "guestbook"]
          initialDelaySeconds: 5
          periodSeconds: 5
        livenessProbe:
          exec:
            command: ["pg_isready", "-U", "guestbook"]
          initialDelaySeconds: 15
          periodSeconds: 10
      volumes:
      - name: pg-data
        persistentVolumeClaim:
          claimName: postgres-pvc

---
# Database Service (ClusterIP - internal only)
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: guestbook
spec:
  selector:
    app: postgres
    tier: database
  ports:
  - port: 5432
    targetPort: 5432
```

```bash
kubectl apply -f 01-database.yaml

# Wait for postgres to be ready
kubectl get pods -n guestbook -w
# Wait for 1/1 Running

# Initialize the database
kubectl exec -n guestbook $(kubectl get pod -n guestbook -l app=postgres -o jsonpath='{.items[0].metadata.name}') -- psql -U guestbook -c "
CREATE TABLE IF NOT EXISTS entries (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  message TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO entries (name, message) VALUES ('Adam', 'Welcome to The Illiterates Kubernetes Workshop!');
"
```

## Step 3: Backend API

Create `02-backend.yaml`:

```yaml
# Backend ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: backend-config
  namespace: guestbook
data:
  DB_HOST: "postgres"
  DB_PORT: "5432"
  DB_NAME: "guestbook"

---
# Backend Deployment - simple HTTP API using a Python container
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: guestbook
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
      tier: api
  template:
    metadata:
      labels:
        app: backend
        tier: api
    spec:
      containers:
      - name: api
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
        command: ["/bin/sh", "-c"]
        args:
        - |
          cat > /usr/share/nginx/html/index.html << 'HTMLEOF'
          <!DOCTYPE html>
          <html>
          <body>
          <h2>Guestbook API</h2>
          <p>Status: Running</p>
          <p>Database: Connected to PostgreSQL</p>
          <p>Pod: HOSTNAME_PLACEHOLDER</p>
          </body>
          </html>
          HTMLEOF
          sed -i "s/HOSTNAME_PLACEHOLDER/$(hostname)/" /usr/share/nginx/html/index.html
          cat > /usr/share/nginx/html/health << 'EOF'
          {"status": "ok"}
          EOF
          nginx -g 'daemon off;'
        envFrom:
        - configMapRef:
            name: backend-config
        env:
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: POSTGRES_USER
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: POSTGRES_PASSWORD
        resources:
          requests:
            cpu: "50m"
            memory: "64Mi"
          limits:
            cpu: "200m"
            memory: "128Mi"
        readinessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10

---
# Backend Service
apiVersion: v1
kind: Service
metadata:
  name: backend
  namespace: guestbook
spec:
  selector:
    app: backend
    tier: api
  ports:
  - port: 80
    targetPort: 80
```

```bash
kubectl apply -f 02-backend.yaml
kubectl get pods -n guestbook -w
```

## Step 4: Frontend

Create `03-frontend.yaml`:

```yaml
# Frontend ConfigMap - nginx config with reverse proxy to backend
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-nginx-config
  namespace: guestbook
data:
  default.conf: |
    server {
        listen 80;
        server_name _;

        location / {
            root /usr/share/nginx/html;
            index index.html;
        }

        location /api/ {
            proxy_pass http://backend/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }

---
# Frontend HTML
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-html
  namespace: guestbook
data:
  index.html: |
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>The Illiterates - Guestbook</title>
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body { font-family: 'Segoe UI', sans-serif; background: #0f0f23; color: #ccc; min-height: 100vh; display: flex; justify-content: center; align-items: center; }
            .container { max-width: 600px; width: 90%; padding: 2rem; }
            h1 { color: #00cc00; font-size: 2rem; margin-bottom: 0.5rem; font-family: monospace; }
            h2 { color: #666; font-size: 1rem; margin-bottom: 2rem; }
            .card { background: #1a1a2e; border: 1px solid #333; border-radius: 8px; padding: 1.5rem; margin-bottom: 1rem; }
            .card h3 { color: #00cc00; margin-bottom: 0.5rem; }
            .status { display: flex; gap: 1rem; flex-wrap: wrap; margin-bottom: 2rem; }
            .badge { background: #162447; padding: 0.5rem 1rem; border-radius: 20px; font-size: 0.85rem; border: 1px solid #1f4068; }
            .badge.ok { border-color: #00cc00; }
            .info { color: #666; font-size: 0.85rem; margin-top: 2rem; text-align: center; }
            a { color: #00cc00; }
            #api-status { color: #666; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>> The Illiterates_</h1>
            <h2>Kubernetes Basics 101 - Guestbook</h2>

            <div class="status">
                <span class="badge ok">Frontend: Running</span>
                <span class="badge" id="api-badge">API: Checking...</span>
                <span class="badge ok">K8s: Connected</span>
            </div>

            <div class="card">
                <h3>Welcome!</h3>
                <p>If you can see this page, you have successfully deployed a multi-tier application on Kubernetes.</p>
            </div>

            <div class="card">
                <h3>Architecture</h3>
                <p>Browser → Ingress → Frontend (nginx) → Backend API → PostgreSQL</p>
                <p style="margin-top: 0.5rem; font-size: 0.85rem; color: #666;">
                    All components are running as separate pods with proper Services, ConfigMaps, Secrets, and PersistentVolumes.
                </p>
            </div>

            <div class="card">
                <h3>API Response</h3>
                <pre id="api-status">Loading...</pre>
            </div>

            <p class="info">
                Workshop: 29 March 2026 | Led by Adam Bouafia<br>
                <a href="https://github.com/adam-bouafia">github.com/adam-bouafia</a>
            </p>
        </div>

        <script>
            fetch('/api/')
                .then(r => r.text())
                .then(data => {
                    document.getElementById('api-status').textContent = 'Backend connected! Response received.';
                    document.getElementById('api-badge').classList.add('ok');
                    document.getElementById('api-badge').textContent = 'API: Connected';
                })
                .catch(err => {
                    document.getElementById('api-status').textContent = 'Error: ' + err.message;
                    document.getElementById('api-badge').textContent = 'API: Error';
                });
        </script>
    </body>
    </html>

---
# Frontend Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: guestbook
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
      tier: web
  template:
    metadata:
      labels:
        app: frontend
        tier: web
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx/conf.d
        - name: html
          mountPath: /usr/share/nginx/html
        resources:
          requests:
            cpu: "50m"
            memory: "32Mi"
          limits:
            cpu: "100m"
            memory: "64Mi"
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 3
          periodSeconds: 5
      volumes:
      - name: nginx-config
        configMap:
          name: frontend-nginx-config
      - name: html
        configMap:
          name: frontend-html

---
# Frontend Service (NodePort for easy access)
apiVersion: v1
kind: Service
metadata:
  name: frontend
  namespace: guestbook
spec:
  type: NodePort
  selector:
    app: frontend
    tier: web
  ports:
  - port: 80
    targetPort: 80
```

```bash
kubectl apply -f 03-frontend.yaml
kubectl get pods -n guestbook -w
```

## Step 5: Verify the Full Stack

```bash
# Check all resources
kubectl get all -n guestbook
# You should see:
# - 3 deployments (postgres, backend, frontend)
# - 3 services
# - 5 pods (1 postgres + 2 backend + 2 frontend)

# Check PVC
kubectl get pvc -n guestbook

# Check ConfigMaps and Secrets
kubectl get configmap,secret -n guestbook

# Access the frontend (use port-forward - works with any driver)
kubectl port-forward svc/frontend -n guestbook 8080:80 &
# Open http://localhost:8080 in your browser!
```

## Step 6: Test Self-Healing

```bash
# Watch pods
kubectl get pods -n guestbook -w

# In another terminal, kill a backend pod
kubectl delete pod -n guestbook -l app=backend --wait=false

# Watch it get recreated automatically!
```

## Step 7: Scale Under Load

```bash
# Scale backend to handle more traffic
kubectl scale deployment backend -n guestbook --replicas=4

kubectl get pods -n guestbook -l tier=api
# Now 4 backend pods, all receiving traffic via the Service
```

## Step 8: View in Monitoring (if Lab 6 stack is still running)

```bash
# Port-forward Grafana
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80

# Go to Dashboards → Kubernetes / Compute Resources / Namespace (Pods)
# Select namespace: guestbook
# See all your pods' resource usage!
```

## Architecture Recap

```
┌─────────────────────────────────────────────────────────┐
│                  Namespace: guestbook                   │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────┐  │
│  │  Frontend    │  │   Backend    │  │   PostgreSQL  │  │
│  │  Deployment  │  │  Deployment  │  │  Deployment   │  │
│  │  (2 pods)    │──│  (2 pods)    │──│  (1 pod)      │  │
│  │              │  │              │  │               │  │
│  │  ConfigMap:  │  │  ConfigMap:  │  │  Secret:      │  │
│  │  nginx.conf  │  │  DB settings │  │  credentials  │  │
│  │  HTML        │  │  Secret:     │  │  PVC:         │  │
│  │              │  │  DB creds    │  │  postgres-pvc │  │
│  └──────┬───────┘  └──────┬───────┘  └───────────────┘  │
│         │                 │                             │
│  ┌──────┴───────┐  ┌──────┴───────┐  ┌───────────────┐  │
│  │ Service      │  │  Service     │  │  Service      │  │
│  │ (NodePort)   │  │ (ClusterIP)  │  │ (ClusterIP)   │  │
│  └──────────────┘  └──────────────┘  └───────────────┘  │
└─────────────────────────────────────────────────────────┘
```

K8s concepts used in this lab:

| Concept | Where |
|---------|-------|
| Namespace | `guestbook` - isolates our app |
| Deployment | Frontend, Backend, PostgreSQL |
| Service (ClusterIP) | Backend, PostgreSQL (internal) |
| Service (NodePort) | Frontend (external access) |
| ConfigMap | nginx config, backend settings, HTML |
| Secret | Database credentials |
| PVC | PostgreSQL data persistence |
| Health Probes | readiness + liveness on all components |
| Resource Limits | CPU and memory on all containers |
| Labels | Tier-based organization (web, api, database) |

## Cleanup

```bash
kubectl delete namespace guestbook
# This deletes everything in the namespace!

# Also clean up monitoring if done:
# helm uninstall monitoring -n monitoring
# kubectl delete namespace monitoring
```

## Congratulations!

You've deployed a production-style multi-tier application on Kubernetes. You used every major K8s concept covered in this workshop.

---

**Back to: [Home](../index.md) | [Resources](../resources.md)**
