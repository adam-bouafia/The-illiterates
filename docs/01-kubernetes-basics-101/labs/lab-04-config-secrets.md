# Lab 4: ConfigMaps & Secrets

**Time: ~15 minutes**

## Objective

Manage application configuration and sensitive data using ConfigMaps and Secrets.

## Exercise 1: ConfigMap from Literals

```bash
# Create a ConfigMap
kubectl create configmap app-settings \
  --from-literal=APP_ENV=development \
  --from-literal=LOG_LEVEL=debug \
  --from-literal=MAX_CONNECTIONS=100

# Inspect it
kubectl get configmap app-settings -o yaml
```

Create a pod that uses it. Save as `configmap-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: config-test
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "env | grep APP_ && env | grep LOG_ && env | grep MAX_ && sleep 3600"]
    envFrom:
    - configMapRef:
        name: app-settings
  restartPolicy: Never
```

```bash
kubectl apply -f configmap-pod.yaml

# Check the environment variables
kubectl logs config-test
# APP_ENV=development
# LOG_LEVEL=debug
# MAX_CONNECTIONS=100
```

## Exercise 2: ConfigMap from File

Create a config file `app-config.ini`:

```ini
[database]
host = postgres
port = 5432
name = myapp_db

[server]
port = 8080
workers = 4
debug = true
```

```bash
# Create ConfigMap from file
kubectl create configmap app-file-config --from-file=app-config.ini

# Verify
kubectl describe configmap app-file-config
```

Mount it as a file in a pod. Save as `configmap-volume-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: config-volume-test
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "cat /etc/config/app-config.ini && sleep 3600"]
    volumeMounts:
    - name: config
      mountPath: /etc/config
  volumes:
  - name: config
    configMap:
      name: app-file-config
  restartPolicy: Never
```

```bash
kubectl apply -f configmap-volume-pod.yaml
kubectl logs config-volume-test
# Shows the contents of app-config.ini
```

## Exercise 3: Secrets

```bash
# Create a secret
kubectl create secret generic db-creds \
  --from-literal=username=admin \
  --from-literal=password='Sup3r$ecret!'

# Inspect - values are base64 encoded
kubectl get secret db-creds -o yaml
# data:
#   password: U3VwM3IkZWNyZXQh
#   username: YWRtaW4=

# Decode
kubectl get secret db-creds -o jsonpath='{.data.password}' | base64 -d
# Sup3r$ecret!
```

Create a pod that uses the secret. Save as `secret-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-test
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "echo DB_USER=$DB_USER && echo DB_PASS=$DB_PASS && sleep 3600"]
    env:
    - name: DB_USER
      valueFrom:
        secretKeyRef:
          name: db-creds
          key: username
    - name: DB_PASS
      valueFrom:
        secretKeyRef:
          name: db-creds
          key: password
  restartPolicy: Never
```

```bash
kubectl apply -f secret-pod.yaml
kubectl logs secret-test
# DB_USER=admin
# DB_PASS=Sup3r$ecret!
```

## Exercise 4: Secrets as Volume Mount

Save as `secret-volume-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-volume-test
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "ls -la /etc/secrets/ && cat /etc/secrets/username && echo && cat /etc/secrets/password && sleep 3600"]
    volumeMounts:
    - name: secret-vol
      mountPath: /etc/secrets
      readOnly: true
  volumes:
  - name: secret-vol
    secret:
      secretName: db-creds
  restartPolicy: Never
```

```bash
kubectl apply -f secret-volume-pod.yaml
kubectl logs secret-volume-test
# Each key becomes a file in /etc/secrets/
```

## Exercise 5: TLS Secret

```bash
# Generate a self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=myapp.local"

# Create TLS secret
kubectl create secret tls my-tls-secret --cert=tls.crt --key=tls.key

# Inspect
kubectl describe secret my-tls-secret
# Type: kubernetes.io/tls

# Clean up temp files
rm tls.key tls.crt
```

## Exercise 6: Updating ConfigMaps

```bash
# Update a ConfigMap value
kubectl edit configmap app-settings
# Change LOG_LEVEL to "info" and save

# For volume-mounted ConfigMaps: files update automatically (within ~60s)
# For env var ConfigMaps: requires pod restart!
kubectl delete pod config-test
kubectl apply -f configmap-pod.yaml
kubectl logs config-test
```

## Cleanup

```bash
kubectl delete pod config-test config-volume-test secret-test secret-volume-test
kubectl delete configmap app-settings app-file-config
kubectl delete secret db-creds my-tls-secret
rm -f app-config.ini configmap-pod.yaml configmap-volume-pod.yaml secret-pod.yaml secret-volume-pod.yaml
```

## Key Takeaways

1. **ConfigMaps** = non-sensitive config (env vars, config files)
2. **Secrets** = sensitive data (passwords, tokens, TLS certs)
3. Both can be consumed as **env vars** or **volume mounts**
4. Volume-mounted configs auto-update; env vars require pod restart
5. Secrets are base64-encoded, **not encrypted** - use external secret managers in production

---

**Next: [Lab 5: Persistent Storage →](lab-05-storage.md)**
