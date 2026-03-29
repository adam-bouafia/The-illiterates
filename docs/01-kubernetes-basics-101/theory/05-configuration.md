# 5. Configuration & Secrets

## The Problem

You don't want to bake configuration into your container image. Different environments (dev, staging, prod) need different configs. And passwords should never be in your image.

Kubernetes provides two objects: **ConfigMaps** (non-sensitive) and **Secrets** (sensitive).

## ConfigMaps

Store configuration data as key-value pairs.

### Creating ConfigMaps

```bash
# From literal values
kubectl create configmap app-config \
  --from-literal=DATABASE_HOST=postgres \
  --from-literal=LOG_LEVEL=info

# From a file
kubectl create configmap nginx-config --from-file=nginx.conf

# From an env file
kubectl create configmap app-env --from-env-file=.env
```

Or declaratively:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  DATABASE_HOST: "postgres"
  DATABASE_PORT: "5432"
  LOG_LEVEL: "info"
  config.yaml: |
    server:
      port: 8080
      debug: false
    cache:
      ttl: 300
```

### Using ConfigMaps in Pods

**As environment variables:**

```yaml
spec:
  containers:
  - name: app
    image: myapp:latest
    envFrom:                    # inject ALL keys as env vars
    - configMapRef:
        name: app-config
    env:                        # or pick specific keys
    - name: DB_HOST
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: DATABASE_HOST
```

**As a mounted file:**

```yaml
spec:
  containers:
  - name: app
    image: myapp:latest
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
  volumes:
  - name: config-volume
    configMap:
      name: app-config
```

This creates files in `/etc/config/` - one file per key.

## Secrets

Like ConfigMaps but for sensitive data. Values are base64-encoded (NOT encrypted by default).

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
type: Opaque
data:
  username: YWRtaW4=          # base64 of "admin"
  password: cEBzc3cwcmQ=      # base64 of "p@ssw0rd"
```

```bash
# Create from literal (auto base64-encodes)
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password='p@ssw0rd'

# Encode/decode base64
echo -n "admin" | base64          # YWRtaW4=
echo "YWRtaW4=" | base64 -d      # admin
```

### Using Secrets in Pods

```yaml
spec:
  containers:
  - name: app
    image: myapp:latest
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: password
    volumeMounts:
    - name: secret-volume
      mountPath: /etc/secrets
      readOnly: true
  volumes:
  - name: secret-volume
    secret:
      secretName: db-credentials
```

!!! warning "Secrets are NOT encrypted at rest by default"
    Base64 is encoding, not encryption. Anyone with API access can read them. For production:

    - Enable [encryption at rest](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/)
    - Use external secret managers (HashiCorp Vault, AWS Secrets Manager, Azure Key Vault)
    - Use tools like [External Secrets Operator](https://external-secrets.io/)

## ConfigMap vs Secret

| | ConfigMap | Secret |
|--|-----------|--------|
| Data type | Non-sensitive | Sensitive |
| Encoding | Plain text | Base64 |
| Size limit | 1 MB | 1 MB |
| Use for | Config files, env vars, feature flags | Passwords, tokens, TLS certs, SSH keys |

## Environment Variables vs Volume Mounts

| | Env Vars | Volume Mounts |
|--|----------|---------------|
| Update behavior | Requires pod restart | Auto-updates (with delay) |
| Format | Key-value pairs | Files |
| Best for | Simple values | Config files, certificates |

---

**Next: [Storage →](06-storage.md)**
