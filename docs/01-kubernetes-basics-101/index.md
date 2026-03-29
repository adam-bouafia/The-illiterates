# Kubernetes Basics 101

**Week 1 | 29 March 2026 | Led by Adam Bouafia**

---

## What is this?

A weekly study group where we break down real-world tech - no fluff, no slides-only sessions. We learn by doing.

**Kubernetes - from zero to deploying and monitoring a real app.**

## Session Format (2 hours)

| Duration | Activity |
|----------|----------|
| 20 min | Theory: What is Kubernetes, architecture, core objects |
| 20 min | **Lab 0-1**: Environment setup + first pod |
| 20 min | Deployments, Services, ConfigMaps & Secrets |
| 20 min | **Lab 2-4**: Deployments, networking, config |
| 20 min | Monitoring, storage & real-world patterns |
| 20 min | **Lab 5-7**: Storage, monitoring + full app deployment |

## Prerequisites

- A laptop with **Fedora Linux** (or any Linux distro)
- Basic terminal knowledge (`cd`, `ls`, `cat`, `vim`/`nano`)
- Docker basics (what a container is)
- Discord for the voice call

## How to Use This Guide

1. **Theory sections** - Read before or during the session
2. **Labs** - Hands-on exercises you follow step-by-step on your own machine
3. **Resources** - Videos, ebooks, and cheat sheets for after the session

## Quick Start

```bash
# Install dependencies (Fedora)
sudo dnf install -y kubernetes1.35-client podman helm

# Install minikube (not in Fedora repos)
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64

# Start your cluster
minikube start --driver=podman

# Verify
kubectl cluster-info
```

## Video Resources

These videos complement the written material:

1. [Kubernetes in 1 Hour](https://youtu.be/daVUONZqn88) - Full overview
2. [Kubernetes Tutorial for Beginners](https://youtu.be/s_o8dwzRlu4) - Step-by-step
3. [Kubernetes Crash Course](https://youtu.be/TlHvYWVUZyc) - Hands-on walkthrough

---

*"The only way to learn is to break things and fix them."*
