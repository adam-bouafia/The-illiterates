# Lab 0: Environment Setup (Fedora)

**Duration: ~15 minutes**

## Objective

Install everything you need to run a local Kubernetes cluster on Fedora Linux.

## Step 1: Install kubectl

`kubectl` is the CLI for interacting with Kubernetes clusters.

```bash
# Fedora uses versioned kubernetes packages
# Check what's available:
sudo dnf search kubernetes | grep client

# Install the latest stable version
# Pick the latest version from the search results above
sudo dnf install -y kubernetes1.35-client
```

!!! note "Fedora doesn't have a generic `kubectl` package"
    Fedora ships versioned packages like `kubernetes1.32-client`, `kubernetes1.33-client`, etc. Pick the latest stable version from the search results.

Verify:

```bash
kubectl version --client
```

## Step 2: Install Minikube

Minikube runs a single-node Kubernetes cluster locally. It's not in the Fedora repos, so grab the binary:

```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64
```

Verify:

```bash
minikube version
```

## Step 3: Install Podman (Container Runtime)

Fedora ships with Podman pre-installed. Verify:

```bash
podman --version
```

If not installed:

```bash
sudo dnf install -y podman
```

## Step 4: Install Helm (Package Manager)

We'll need this for Lab 6 (monitoring stack).

```bash
sudo dnf install -y helm
```

If `helm` is not in your repos:

```bash
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

Verify:

```bash
helm version
```

## Step 5: Start Your Cluster

```bash
# Enable rootless mode (required on Fedora - podman refuses root, and sudo needs NOPASSWD)
minikube config set rootless true

# Start minikube with Podman driver (Fedora-native, no Docker needed)
minikube start --driver=podman --container-runtime=containerd
```

The first run will download ~500MB of images. After that, starts are fast.

You should see something like:

```
minikube v1.xx on Fedora xx
Using the podman driver
Using rootless Podman driver
Starting "minikube" primary control-plane node in "minikube" cluster
Preparing Kubernetes v1.35.x on containerd ...
Verifying Kubernetes components...
Enabled addons: default-storageclass, storage-provisioner
Done! kubectl is now configured to use "minikube" cluster
```

## Step 5b: Create a Lab Workspace

All lab exercises use YAML files. Create a folder to keep them organized inside the repo:

```bash
cd /path/to/The-illiterates
mkdir -p k8s-labs/29.03.2026
cd k8s-labs/29.03.2026
```

All YAML files created during the labs go here. Run all lab commands from this folder.

!!! warning "If podman driver fails"
    Try these alternatives in order:

    ```bash
    # Option 1: Use KVM2 driver instead (needs libvirt)
    sudo dnf install -y @virtualization
    minikube start --driver=kvm2

    # Option 3: Default driver (minikube picks the best available)
    minikube start
    ```

## Step 6: Verify Everything Works

```bash
# Cluster info
kubectl cluster-info
# Kubernetes control plane is running at https://192.168.xx.xx:8443

# Nodes
kubectl get nodes
# NAME       STATUS   ROLES           AGE   VERSION
# minikube   Ready    control-plane   1m    v1.32.x

# System pods
kubectl get pods -n kube-system
# You should see coredns, etcd, kube-apiserver, etc.
```

## Step 7: Enable Useful Addons

```bash
minikube addons enable metrics-server
minikube addons enable dashboard
minikube addons enable ingress
```

Verify addons are running:

```bash
# Check metrics-server is up (may take a minute)
kubectl get pods -n kube-system | grep metrics-server

# If metrics-server fails, install it manually:
# kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

## Troubleshooting

### "Exiting due to PROVIDER_PODMAN_ERROR"

```bash
# Check podman is working
podman info

# Try with root privileges
sudo minikube start --driver=podman
```

### "kubectl: command not found"

```bash
# Make sure /usr/local/bin is in PATH
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
source ~/.bashrc
```

### Minikube uses too much RAM

```bash
# Start with specific resources
minikube start --memory=2048 --cpus=2
```

### minikube service not opening browser

On Fedora with podman, `minikube service` may not work. Use port-forward instead:

```bash
# Instead of: minikube service <name> --url
# Use:
kubectl port-forward svc/<service-name> 8080:80
# Then open http://localhost:8080
```

### Reset everything

```bash
minikube delete
minikube start --driver=podman
```

## Cheat Sheet

```bash
minikube status          # check cluster status
minikube stop            # stop cluster (preserves state)
minikube start           # restart cluster
minikube delete          # destroy cluster
minikube dashboard       # open web dashboard
minikube ssh             # SSH into the minikube VM/container
minikube addons list     # see available addons
```

---

**You're ready! Next: [Lab 1: Your First Pod -](lab-01-first-pod.md)**
