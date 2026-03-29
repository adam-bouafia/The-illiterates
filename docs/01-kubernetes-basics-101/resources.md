# Resources

## Video Resources

1. [Kubernetes in 1 Hour](https://youtu.be/daVUONZqn88) - Full overview
2. [Kubernetes Tutorial for Beginners](https://youtu.be/s_o8dwzRlu4) - Step-by-step
3. [Kubernetes Crash Course](https://youtu.be/TlHvYWVUZyc) - Hands-on walkthrough

## Ebooks

[Google Drive folder with all ebooks](https://drive.google.com/drive/folders/1I0ZJBgQWHZ6T5wCWiO1jt051frysMMt1?usp=sharing) | Also available locally in `~/Downloads/Ebooks/`

| File | Topic |
|------|-------|
| `ma-kubernetes-clusters-dummies-ebook` | Kubernetes for Dummies |
| `cl-oreilly-generative-ai-kubernetes` | Generative AI on Kubernetes |
| `vi-get-started-with-openshift-virtualization` | OpenShift Virtualization |
| `cl-migrate-virtual-machines-ebook` | VM to K8s Migration |
| `li-rhel-experience-ebook` | RHEL Experience |
| `li-maximize-linux-ebook` | Maximize Linux |
| `ma-network-automation-for-everyone-ebook` | Network Automation |
| `The-Modern-Developer-ebook-Red-Hat-Developer` | Modern Developer Practices |

## Official Documentation

- [Kubernetes Official Docs](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Kubernetes API Reference](https://kubernetes.io/docs/reference/kubernetes-api/)
- [Helm Documentation](https://helm.sh/docs/)

## Interactive Learning

- [Kubernetes Playground (Killercoda)](https://killercoda.com/playgrounds/scenario/kubernetes)
- [Play with Kubernetes](https://labs.play-with-k8s.com/)
- [Kubernetes the Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)

## kubectl Cheat Sheet

```bash
# --- Cluster ---
kubectl cluster-info
kubectl get nodes
kubectl top nodes

# --- Pods ---
kubectl get pods [-n namespace] [-l label=value]
kubectl describe pod <name>
kubectl logs <pod> [-c container] [-f]
kubectl exec -it <pod> -- bash
kubectl port-forward <pod> <local>:<remote>
kubectl delete pod <name>
kubectl top pods

# --- Deployments ---
kubectl get deployments
kubectl create deployment <name> --image=<image>
kubectl scale deployment <name> --replicas=N
kubectl set image deployment/<name> <container>=<image>
kubectl rollout status deployment/<name>
kubectl rollout undo deployment/<name>

# --- Services ---
kubectl get svc
kubectl expose deployment <name> --port=<port> --type=<type>
kubectl get endpoints <name>

# --- Config ---
kubectl get configmap,secret [-n namespace]
kubectl create configmap <name> --from-literal=KEY=VALUE
kubectl create secret generic <name> --from-literal=KEY=VALUE

# --- Storage ---
kubectl get pv,pvc

# --- Namespaces ---
kubectl get ns
kubectl create ns <name>
kubectl get all -n <namespace>

# --- Debugging ---
kubectl describe <resource> <name>
kubectl get events --sort-by=.lastTimestamp
kubectl get pods --field-selector=status.phase!=Running
```

## What's Next?

Topics for future Illiterates sessions:

- **Helm deep dive** - Creating your own charts
- **CI/CD with Kubernetes** - GitHub Actions + ArgoCD
- **Service Mesh** - Istio or Linkerd
- **Kubernetes Security** - RBAC, Pod Security Standards, OPA
- **Cloud Kubernetes** - AKS (Azure), EKS (AWS), GKE (Google)
- **GitOps** - ArgoCD or Flux in depth
- **Kubernetes Networking** - CNI plugins, Calico, Cilium

---

*The Illiterates - Learning by breaking things since 2026*
