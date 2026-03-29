# 2. Architecture Deep Dive

## The Big Picture

A Kubernetes cluster has two types of machines:

```
┌────────────────────────────────────────────────────┐
│                   CONTROL PLANE                    │
│  ┌──────────┐ ┌───────────┐ ┌──────────┐ ┌───────┐ │
│  │ API      │ │ Scheduler │ │Controller│ │ etcd  │ │
│  │ Server   │ │           │ │ Manager  │ │       │ │
│  └──────────┘ └───────────┘ └──────────┘ └───────┘ │
└──────────────────────┬─────────────────────────────┘
                       │ (API calls)
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
┌──────────────┐┌──────────────┐┌──────────────┐
│   WORKER     ││   WORKER     ││   WORKER     │
│   NODE 1     ││   NODE 2     ││   NODE 3     │
│ ┌──────────┐ ││ ┌──────────┐ ││ ┌──────────┐ │
│ │ kubelet  │ ││ │ kubelet  │ ││ │ kubelet  │ │
│ │ kube-    │ ││ │ kube-    │ ││ │ kube-    │ │
│ │ proxy    │ ││ │ proxy    │ ││ │ proxy    │ │
│ │ container│ ││ │ container│ ││ │ container│ │
│ │ runtime  │ ││ │ runtime  │ ││ │ runtime  │ │
│ ├──────────┤ ││ ├──────────┤ ││ ├──────────┤ │
│ │ Pod  Pod │ ││ │ Pod  Pod │ ││ │ Pod      │ │
│ └──────────┘ ││ └──────────┘ ││ └──────────┘ │
└──────────────┘└──────────────┘└──────────────┘
```

## Control Plane Components

### API Server (`kube-apiserver`)
The **front door** to Kubernetes. Every `kubectl` command, every internal component - they all talk through the API Server.

```bash
# When you run this:
kubectl get pods
# You're making a REST call to the API server:
# GET /api/v1/namespaces/default/pods
```

- Authenticates and authorizes requests
- Validates and processes API objects
- The ONLY component that talks to etcd

### etcd
A **distributed key-value store** that holds ALL cluster state.

- Every pod, service, deployment, config - it's all in etcd
- If etcd dies and you have no backup, your cluster config is gone
- Uses the Raft consensus algorithm for distributed consistency

Think of it as the **database** of the cluster.

### Scheduler (`kube-scheduler`)
Watches for newly created pods with no assigned node, then **picks the best node** for them.

Decision factors:
- Resource requests (CPU, memory)
- Node affinity/anti-affinity rules
- Taints and tolerations
- Data locality

### Controller Manager (`kube-controller-manager`)
Runs a bunch of **control loops** that watch the cluster state and make changes to move toward the desired state.

Key controllers:

| Controller | What it does |
|-----------|-------------|
| Deployment | Manages ReplicaSets for rolling updates |
| ReplicaSet | Ensures N pods are always running |
| Node | Monitors node health |
| Job | Runs pods to completion |
| Service Account | Creates default accounts for namespaces |

**The reconciliation loop** - the core pattern:
```
1. Observe current state
2. Compare with desired state
3. Take action to converge
4. Repeat forever
```

## Worker Node Components

### kubelet
The **agent** running on every node. It:

- Receives pod specs from the API server
- Ensures containers are running and healthy
- Reports node and pod status back

```
API Server: "Run this pod on your node"
kubelet: "Got it. Starting containers... Done. Status: Running"
```

### kube-proxy
Handles **networking rules** on each node. Implements Services by maintaining network rules (iptables/IPVS) that route traffic to the right pods.

### Container Runtime
The software that actually **runs containers**. Kubernetes supports any CRI-compatible runtime:

- **containerd** (most common, default in minikube)
- **CRI-O** (used by OpenShift, lighter)
- **Podman** (daemonless, Fedora-friendly)

!!! note "Docker is NOT a container runtime for K8s anymore"
    Since K8s 1.24, Docker (dockershim) was removed. K8s uses containerd or CRI-O directly. Docker images still work - it's just the runtime that changed.

## How It All Works Together

**Example: You run `kubectl apply -f deployment.yaml`**

```
1. kubectl → API Server: "Create this Deployment"
2. API Server → etcd: stores the Deployment object
3. Deployment Controller notices new Deployment → creates ReplicaSet
4. ReplicaSet Controller notices new RS → creates Pod objects
5. Scheduler notices unscheduled Pods → assigns them to nodes
6. kubelet on each node notices assigned Pods → starts containers
7. kube-proxy updates network rules for any Services
```

Every step is **asynchronous and event-driven**. Components watch for changes and react.

## Local vs Production Clusters

| | Minikube | Kind | k3s | Full K8s |
|--|---------|------|-----|----------|
| Nodes | 1 VM | Docker containers | Lightweight | Multi-machine |
| Use case | Learning, local dev | CI/CD, testing | Edge, IoT, dev | Production |
| Setup | `minikube start` | `kind create cluster` | `curl -sfL \| sh` | kubeadm, managed |
| Resources | ~2GB RAM | ~512MB per node | ~512MB | 2GB+ per node |

For our workshop, we'll use **Minikube** - it runs a single-node cluster inside a VM or container on your laptop.

---

**Next: [Core Objects →](03-core-objects.md)**
