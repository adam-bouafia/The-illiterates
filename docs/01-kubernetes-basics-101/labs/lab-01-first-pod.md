# Lab 1: Your First Pod

**Time: ~15 minutes**

## Objective

Create, inspect, and interact with a Kubernetes Pod.

## Exercise 1: Run a Pod Imperatively

The fastest way to create a pod:

```bash
kubectl run my-nginx --image=nginx:1.25 --port=80
```

Check it:
```bash
kubectl get pods
# NAME       READY   STATUS    RESTARTS   AGE
# my-nginx   1/1     Running   0          10s
```

Get detailed info:
```bash
kubectl describe pod my-nginx
```

Look for:
- **Status**: Should be `Running`
- **IP**: The pod's internal IP
- **Events**: The sequence of actions K8s took (pull image, create container, start)

## Exercise 2: Interact with the Pod

```bash
# View logs
kubectl logs my-nginx

# Shell into the pod
kubectl exec -it my-nginx -- bash

# Inside the pod:
curl localhost:80
cat /etc/nginx/nginx.conf
exit

# Port-forward to access from your laptop
kubectl port-forward my-nginx 8080:80
# Now open http://localhost:8080 in your browser
# Ctrl+C to stop port-forward
```

## Exercise 3: Create a Pod Declaratively

Create a file `pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-server
  labels:
    app: web
    env: lab
spec:
  containers:
  - name: nginx
    image: nginx:1.25
    ports:
    - containerPort: 80
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
      limits:
        memory: "128Mi"
        cpu: "250m"
```

Apply it:
```bash
kubectl apply -f pod.yaml
```

Verify:
```bash
kubectl get pods --show-labels
# NAME         READY   STATUS    RESTARTS   AGE   LABELS
# my-nginx     1/1     Running   0          5m    run=my-nginx
# web-server   1/1     Running   0          10s   app=web,env=lab
```

## Exercise 4: Multi-Container Pod

Create `multi-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-container
spec:
  containers:
  - name: web
    image: nginx:1.25
    ports:
    - containerPort: 80
    volumeMounts:
    - name: shared-logs
      mountPath: /var/log/nginx
  - name: log-reader
    image: busybox
    command: ["sh", "-c", "tail -f /logs/access.log"]
    volumeMounts:
    - name: shared-logs
      mountPath: /logs
  volumes:
  - name: shared-logs
    emptyDir: {}
```

```bash
kubectl apply -f multi-pod.yaml

# Check both containers are running
kubectl get pod multi-container
# READY shows 2/2

# View logs of specific container
kubectl logs multi-container -c web
kubectl logs multi-container -c log-reader

# Generate traffic and watch the log-reader
kubectl exec multi-container -c web -- curl -s localhost
kubectl logs multi-container -c log-reader
```

## Exercise 5: Pod Lifecycle

```bash
# Watch pods in real-time
kubectl get pods -w

# In another terminal, delete a pod
kubectl delete pod web-server

# Watch it go: Running → Terminating → gone
# Note: the pod is NOT recreated - raw pods don't self-heal!
```

## Cleanup

```bash
kubectl delete pod my-nginx web-server multi-container
```

## Key Takeaways

1. Pods are the smallest deployable unit
2. You can create them imperatively (`kubectl run`) or declaratively (YAML + `kubectl apply`)
3. Pods can hold multiple containers that share network and storage
4. Raw pods **don't self-heal** - if they die, they're gone (use Deployments instead)
5. `kubectl describe`, `logs`, and `exec` are your best debugging friends

---

**Next: [Lab 2: Deployments & Scaling →](lab-02-deployments.md)**
