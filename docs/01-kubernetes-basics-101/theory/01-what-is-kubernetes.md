# 1. What is Kubernetes?

## The Problem

Imagine you have an app running in a Docker container. Works great on your laptop. Now you need to:

- Run 50 copies of it across 10 servers
- Replace crashed containers automatically
- Roll out updates without downtime
- Scale up when traffic spikes, scale down at night
- Manage configs and secrets across all instances

You *could* SSH into each server and run `docker run` manually. You won't. That's why Kubernetes exists.

## The Answer

**Kubernetes (K8s)** is a container orchestration platform. It takes your containers and manages them across a cluster of machines.

You tell Kubernetes **what you want** (declarative), and it figures out **how to make it happen**.

```yaml
# You say: "I want 3 copies of my nginx running"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  replicas: 3         # <-- "I want 3"
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
```

Kubernetes then:

- Schedules 3 pods across available nodes
- Restarts any that crash
- Lets you update the image version with zero downtime

## Key Concepts (Preview)

| Concept | What it is | Analogy |
|---------|-----------|---------|
| **Cluster** | A set of machines running K8s | The whole datacenter |
| **Node** | A single machine in the cluster | One server |
| **Pod** | Smallest deployable unit (1+ containers) | One "instance" of your app |
| **Deployment** | Manages pod replicas + updates | The "desired state" manager |
| **Service** | Stable network endpoint for pods | A load balancer |
| **Namespace** | Virtual cluster isolation | Folders for organization |

## Why Not Just Docker Compose?

| Feature | Docker Compose | Kubernetes |
|---------|---------------|-----------|
| Multi-machine | No | Yes |
| Auto-healing | No | Yes |
| Rolling updates | Manual | Built-in |
| Service discovery | Basic | Advanced (DNS, labels) |
| Scaling | Manual | Automatic (HPA) |
| Production-ready | For dev/staging | Yes |

**Docker Compose** = great for local dev and simple deployments.
**Kubernetes** = when you need reliability, scale, and automation in production.

## A Brief History

- **2014**: Google open-sources Kubernetes (based on 15 years of internal systems: Borg & Omega)
- **2015**: v1.0 released, donated to CNCF (Cloud Native Computing Foundation)
- **2016-now**: Becomes the industry standard for container orchestration
- **Today**: Every major cloud (Azure AKS, AWS EKS, GCP GKE) offers managed Kubernetes

## Who Uses It?

Spotify, Airbnb, Reddit, Tinder, The New York Times, Adidas, ING Bank, and basically every tech company that runs containers at scale.

---

**Next: [Architecture Deep Dive →](02-architecture.md)**
