# Lab 3: Services & Networking

**Time: ~20 minutes**

## Objective

Expose pods via Services, understand DNS, and set up Ingress.

## Setup

First, create a deployment to expose:

```bash
kubectl create deployment web --image=nginx:1.25 --replicas=3
kubectl create deployment api --image=hashicorp/http-echo --replicas=2 \
  -- -text="Hello from API"
```

## Exercise 1: ClusterIP Service

```bash
# Create a ClusterIP service for the web deployment
kubectl expose deployment web --port=80 --target-port=80 --type=ClusterIP

# Check it
kubectl get svc web
# NAME   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
# web    ClusterIP   10.96.123.45    <none>        80/TCP    5s

# Test from inside the cluster - run a temporary pod
kubectl run test-pod --rm -it --image=busybox -- sh

# Inside the test pod:
wget -qO- http://web
# You should see the nginx welcome page HTML

# DNS works too:
wget -qO- http://web.default.svc.cluster.local
nslookup web
exit
```

## Exercise 2: NodePort Service

```bash
# Expose API as NodePort
kubectl expose deployment api --port=5678 --target-port=5678 --type=NodePort

# Check assigned port
kubectl get svc api
# NAME   TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
# api    NodePort   10.96.78.90    <none>        5678:31234/TCP   5s
#                                                     ↑ random NodePort

# Option 1: minikube service (may not work with podman driver)
minikube service api --url

# Option 2: port-forward (always works)
kubectl port-forward svc/api 5678:5678 &
curl http://localhost:5678
# Hello from API
```

## Exercise 3: Service Discovery via DNS

```bash
# Run a debug pod
kubectl run dns-test --rm -it --image=busybox -- sh

# Inside:
# Resolve service names
nslookup web
# Server:    10.96.0.10
# Name:      web.default.svc.cluster.local
# Address:   10.96.123.45

nslookup api
nslookup kubernetes   # the API server service

# Full FQDN pattern:
# <service>.<namespace>.svc.cluster.local

exit
```

## Exercise 4: Load Balancing

Verify that the service distributes traffic across pods:

```bash
# Create a deployment that shows its hostname
kubectl create deployment echo --image=hashicorp/http-echo --replicas=3 \
  -- -text="I am a pod"

# Hmm, they all say the same thing. Let's use a different approach:
kubectl delete deployment echo

# Create pods that show their hostname
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: echo
  template:
    metadata:
      labels:
        app: echo
    spec:
      containers:
      - name: echo
        image: nginx:1.25
        command: ["/bin/sh", "-c"]
        args:
        - |
          echo "I am $(hostname)" > /usr/share/nginx/html/index.html
          nginx -g 'daemon off;'
        ports:
        - containerPort: 80
EOF

kubectl expose deployment echo --port=80

# Now hit the service multiple times from inside the cluster
kubectl run lb-test --rm -it --image=busybox -- sh

# Inside:
for i in $(seq 1 10); do wget -qO- http://echo; done
# I am echo-7d9c456f8d-abc12
# I am echo-7d9c456f8d-def34
# I am echo-7d9c456f8d-abc12
# I am echo-7d9c456f8d-ghi56
# ... traffic is distributed!

exit
```

## Exercise 5: Ingress

```bash
# Make sure ingress addon is enabled
minikube addons enable ingress

# Wait for ingress controller to be ready
kubectl get pods -n ingress-nginx
# Wait until STATUS is Running
```

Create `ingress.yaml`:

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
      - path: /web
        pathType: Prefix
        backend:
          service:
            name: web
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api
            port:
              number: 5678
```

```bash
kubectl apply -f ingress.yaml

# Get the minikube IP
minikube ip
# 192.168.49.2

# Add to /etc/hosts
echo "$(minikube ip) myapp.local" | sudo tee -a /etc/hosts

# Test
curl http://myapp.local/web    # nginx welcome page
curl http://myapp.local/api    # Hello from API
```

## Exercise 6: Network Debugging

When things don't work, debug like this:

```bash
# 1. Is the pod running?
kubectl get pods -l app=web

# 2. Can you reach the pod directly?
kubectl exec -it $(kubectl get pod -l app=web -o jsonpath='{.items[0].metadata.name}') -- curl localhost:80

# 3. Does the service have endpoints?
kubectl get endpoints web
# NAME   ENDPOINTS                                         AGE
# web    10.244.0.5:80,10.244.0.6:80,10.244.0.7:80        5m
# If ENDPOINTS is <none>, the selector doesn't match any pods!

# 4. Can you reach the service from inside the cluster?
kubectl run debug --rm -it --image=busybox -- wget -qO- http://web

# 5. Check service details
kubectl describe svc web
```

## Cleanup

```bash
kubectl delete deployment web api echo
kubectl delete svc web api echo
kubectl delete ingress app-ingress
# Remove the /etc/hosts entry if you want
sudo sed -i '/myapp.local/d' /etc/hosts
```

## Key Takeaways

1. **ClusterIP**: Internal only - default, most common
2. **NodePort**: External access via `<NodeIP>:<Port>`
3. Services use **label selectors** to find pods
4. K8s DNS: `<service>.<namespace>.svc.cluster.local`
5. Services load-balance traffic across pods automatically
6. **Ingress** = HTTP routing (path/host-based) for external traffic
7. Debug order: pod → direct access → endpoints → service → ingress

---

**Next: [Lab 4: ConfigMaps & Secrets →](lab-04-config-secrets.md)**
