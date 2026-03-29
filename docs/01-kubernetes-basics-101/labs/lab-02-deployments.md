# Lab 2: Deployments & Scaling

**Time: ~20 minutes**

## Objective

Create Deployments, scale them, perform rolling updates and rollbacks.

## Exercise 1: Create a Deployment

Create `deployment.yaml`:

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
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx:1.24
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: "50m"
            memory: "64Mi"
```

```bash
kubectl apply -f deployment.yaml

# Watch pods come up
kubectl get pods -l app=web
# NAME                       READY   STATUS    RESTARTS   AGE
# web-app-7d9c456f8d-abc12   1/1     Running   0          5s
# web-app-7d9c456f8d-def34   1/1     Running   0          5s
# web-app-7d9c456f8d-ghi56   1/1     Running   0          5s

# Check the deployment
kubectl get deployment web-app
# NAME      READY   UP-TO-DATE   AVAILABLE   AGE
# web-app   3/3     3            3           30s

# Check the ReplicaSet created automatically
kubectl get rs
```

## Exercise 2: Self-Healing

```bash
# Delete a pod and watch it get recreated
kubectl delete pod $(kubectl get pods -l app=web -o jsonpath='{.items[0].metadata.name}')

# Immediately check
kubectl get pods -l app=web
# A new pod is already being created! (STATUS: ContainerCreating)

# Wait a moment
kubectl get pods -l app=web
# Back to 3/3 Running
```

The Deployment controller detected a missing pod and created a replacement.

## Exercise 3: Scaling

```bash
# Scale up to 5 replicas
kubectl scale deployment web-app --replicas=5

kubectl get pods -l app=web
# Now 5 pods running

# Scale down to 2
kubectl scale deployment web-app --replicas=2

kubectl get pods -l app=web
# 3 pods are Terminating, 2 remain

# You can also edit the YAML and re-apply:
# Change replicas: 4 in deployment.yaml
kubectl apply -f deployment.yaml
```

## Exercise 4: Rolling Update

Update the nginx version from 1.24 to 1.25:

```bash
# Method 1: Command line
kubectl set image deployment/web-app nginx=nginx:1.25

# Watch the rollout happen
kubectl rollout status deployment/web-app
# Waiting for deployment "web-app" rollout to finish: 1 out of 3 new replicas have been updated...
# Waiting for deployment "web-app" rollout to finish: 2 out of 3 new replicas have been updated...
# deployment "web-app" successfully rolled out

# Check the new ReplicaSet
kubectl get rs
# NAME                  DESIRED   CURRENT   READY
# web-app-7d9c456f8d    0         0         0      ← old (nginx:1.24)
# web-app-85c4f7d9b2    3         3         3      ← new (nginx:1.25)

# Verify the image
kubectl describe deployment web-app | grep Image
#   Image: nginx:1.25
```

## Exercise 5: Rollback

```bash
# View rollout history
kubectl rollout history deployment/web-app
# REVISION  CHANGE-CAUSE
# 1         <none>
# 2         <none>

# Rollback to previous version
kubectl rollout undo deployment/web-app

# Watch it
kubectl rollout status deployment/web-app

# Verify - should be back to nginx:1.24
kubectl describe deployment web-app | grep Image

# Rollback to a specific revision
kubectl rollout undo deployment/web-app --to-revision=2
```

## Exercise 6: Update Strategy

Edit your deployment to use a controlled rolling update:

```yaml
spec:
  replicas: 4
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1          # at most 5 pods during update (4+1)
      maxUnavailable: 0     # never go below 4 running pods
```

```bash
kubectl apply -f deployment.yaml

# Now update and watch carefully
kubectl set image deployment/web-app nginx=nginx:1.25

# In another terminal, watch pods in real-time:
kubectl get pods -l app=web -w
# You'll see: new pod starts → becomes Ready → old pod terminates
```

Try `maxUnavailable: 1` and `maxSurge: 0` - the opposite strategy (replace in-place, no extra pods).

## Exercise 7: Resource Monitoring

```bash
# If metrics-server is enabled:
kubectl top pods -l app=web
# NAME                       CPU(cores)   MEMORY(bytes)
# web-app-85c4f7d9b2-abc12   1m           3Mi
# web-app-85c4f7d9b2-def34   1m           3Mi
# web-app-85c4f7d9b2-ghi56   1m           3Mi
```

## Cleanup

```bash
kubectl delete deployment web-app
```

## Key Takeaways

1. Deployments manage pods via ReplicaSets - always use them instead of raw pods
2. Self-healing: deleted pods are automatically replaced
3. Scaling is instant: `kubectl scale` or change `replicas`
4. Rolling updates: change the image, K8s gradually replaces pods
5. Rollbacks: K8s keeps old ReplicaSets, so you can undo instantly
6. Update strategy controls the tradeoff between speed and availability

---

**Next: [Lab 3: Services & Networking →](lab-03-services.md)**
