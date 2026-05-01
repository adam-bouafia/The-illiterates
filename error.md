neo@Utopia:~$ kubectl get pods -n monitoring
NAME                                                     READY   STATUS                  RESTARTS        AGE
alertmanager-monitoring-kube-prometheus-alertmanager-0   0/2     Init:CrashLoopBackOff   5 (2m41s ago)   6m57s
monitoring-grafana-7cf6c9fcf5-84czj                      3/3     Running                 0               7m29s
monitoring-kube-prometheus-operator-6b4c47dd76-2ffgb     1/1     Running                 0               7m29s
monitoring-kube-state-metrics-67d5f7bf68-s6t4h           1/1     Running                 0               7m29s
monitoring-prometheus-node-exporter-bpf6f                1/1     Running                 0               7m29s
prometheus-monitoring-kube-prometheus-prometheus-0       0/2     Init:CrashLoopBackOff   5 (2m27s ago)   6m57s
neo@Utopia:~$ kubectl describe pod alertmanager-monitoring-kube-prometheus-alertmanager-0 -n monitoring
Name:             alertmanager-monitoring-kube-prometheus-alertmanager-0
Namespace:        monitoring
Priority:         0
Service Account:  monitoring-kube-prometheus-alertmanager
Node:             minikube/192.168.49.2
Start Time:       Sun, 19 Apr 2026 19:21:31 +0200
Labels:           alertmanager=monitoring-kube-prometheus-alertmanager
                  app.kubernetes.io/instance=monitoring-kube-prometheus-alertmanager
                  app.kubernetes.io/managed-by=prometheus-operator
                  app.kubernetes.io/name=alertmanager
                  app.kubernetes.io/version=0.32.0
                  apps.kubernetes.io/pod-index=0
                  controller-revision-hash=alertmanager-monitoring-kube-prometheus-alertmanager-6596d789d
                  statefulset.kubernetes.io/pod-name=alertmanager-monitoring-kube-prometheus-alertmanager-0
Annotations:      kubectl.kubernetes.io/default-container: alertmanager
Status:           Pending
SeccompProfile:   RuntimeDefault
IP:               10.244.0.21
IPs:
  IP:           10.244.0.21
Controlled By:  StatefulSet/alertmanager-monitoring-kube-prometheus-alertmanager
Init Containers:
  init-config-reloader:
    Container ID:  containerd://9160461569f44330bdf8003cf40fa2c753323cf233dacacb366deb2085052a15
    Image:         quay.io/prometheus-operator/prometheus-config-reloader:v0.90.1
    Image ID:      quay.io/prometheus-operator/prometheus-config-reloader@sha256:693faa0b87243cddca2cffb13586e4e2778b0cdf319cb2e601ba7af3fd19ef7d
    Port:          8081/TCP (reloader-init)
    Host Port:     0/TCP (reloader-init)
    Command:
      /bin/prometheus-config-reloader
    Args:
      --watch-interval=0
      --listen-address=:8081
      --config-file=/etc/alertmanager/config/alertmanager.yaml.gz
      --config-envsubst-file=/etc/alertmanager/config_out/alertmanager.env.yaml
      --watched-dir=/etc/alertmanager/config
    State:      Terminated
      Reason:   Error
      Message:  ts=2026-04-19T17:28:34.163163275Z level=info caller=/workspace/cmd/prometheus-config-reloader/main.go:148 msg="Starting prometheus-config-reloader" version="(version=0.90.1, branch=, revision=32d1b3d)" build_context="(go=go1.25.8, platform=linux/amd64, user=, date=20260325-10:28:31, tags=unknown)"
ts=2026-04-19T17:28:34.163384448Z level=info caller=/workspace/internal/goruntime/cpu.go:27 msg="Leaving GOMAXPROCS=8: CPU quota undefined"
level=info ts=2026-04-19T17:28:34.16396883Z caller=reloader.go:282 msg="reloading via HTTP"
ts=2026-04-19T17:28:34.164034361Z level=error caller=/workspace/cmd/prometheus-config-reloader/main.go:225 msg="Failed to run" err="too many open files\ncreate watcher\ngithub.com/thanos-io/thanos/pkg/reloader.(*watcher).addPath\n\t/go/pkg/mod/github.com/thanos-io/thanos@v0.41.0/pkg/reloader/reloader.go:786\ngithub.com/thanos-io/thanos/pkg/reloader.(*watcher).addFile\n\t/go/pkg/mod/github.com/thanos-io/thanos@v0.41.0/pkg/reloader/reloader.go:808\ngithub.com/thanos-io/thanos/pkg/reloader.(*Reloader).Watch\n\t/go/pkg/mod/github.com/thanos-io/thanos@v0.41.0/pkg/reloader/reloader.go:288\nmain.main.func1\n\t/workspace/cmd/prometheus-config-reloader/main.go:186\ngithub.com/oklog/run.(*Group).Run.func1\n\t/go/pkg/mod/github.com/oklog/run@v1.2.0/group.go:38\nruntime.goexit\n\t/usr/local/go/src/runtime/asm_amd64.s:1693\nadd config file /etc/alertmanager/config/alertmanager.yaml.gz to watcher\ngithub.com/thanos-io/thanos/pkg/reloader.(*Reloader).Watch\n\t/go/pkg/mod/github.com/thanos-io/thanos@v0.41.0/pkg/reloader/reloader.go:289\nmain.main.func1\n\t/workspace/cmd/prometheus-config-reloader/main.go:186\ngithub.com/oklog/run.(*Group).Run.func1\n\t/go/pkg/mod/github.com/oklog/run@v1.2.0/group.go:38\nruntime.goexit\n\t/usr/local/go/src/runtime/asm_amd64.s:1693"

      Exit Code:  1
      Started:    Sun, 19 Apr 2026 19:28:34 +0200
      Finished:   Sun, 19 Apr 2026 19:28:34 +0200
    Last State:   Terminated
      Reason:     Error
      Message:    ts=2026-04-19T17:25:47.149943822Z level=info caller=/workspace/cmd/prometheus-config-reloader/main.go:148 msg="Starting prometheus-config-reloader" version="(version=0.90.1, branch=, revision=32d1b3d)" build_context="(go=go1.25.8, platform=linux/amd64, user=, date=20260325-10:28:31, tags=unknown)"
ts=2026-04-19T17:25:47.150207783Z level=info caller=/workspace/internal/goruntime/cpu.go:27 msg="Leaving GOMAXPROCS=8: CPU quota undefined"
level=info ts=2026-04-19T17:25:47.150746906Z caller=reloader.go:282 msg="reloading via HTTP"
ts=2026-04-19T17:25:47.15081781Z level=error caller=/workspace/cmd/prometheus-config-reloader/main.go:225 msg="Failed to run" err="too many open files\ncreate watcher\ngithub.com/thanos-io/thanos/pkg/reloader.(*watcher).addPath\n\t/go/pkg/mod/github.com/thanos-io/thanos@v0.41.0/pkg/reloader/reloader.go:786\ngithub.com/thanos-io/thanos/pkg/reloader.(*watcher).addFile\n\t/go/pkg/mod/github.com/thanos-io/thanos@v0.41.0/pkg/reloader/reloader.go:808\ngithub.com/thanos-io/thanos/pkg/reloader.(*Reloader).Watch\n\t/go/pkg/mod/github.com/thanos-io/thanos@v0.41.0/pkg/reloader/reloader.go:288\nmain.main.func1\n\t/workspace/cmd/prometheus-config-reloader/main.go:186\ngithub.com/oklog/run.(*Group).Run.func1\n\t/go/pkg/mod/github.com/oklog/run@v1.2.0/group.go:38\nruntime.goexit\n\t/usr/local/go/src/runtime/asm_amd64.s:1693\nadd config file /etc/alertmanager/config/alertmanager.yaml.gz to watcher\ngithub.com/thanos-io/thanos/pkg/reloader.(*Reloader).Watch\n\t/go/pkg/mod/github.com/thanos-io/thanos@v0.41.0/pkg/reloader/reloader.go:289\nmain.main.func1\n\t/workspace/cmd/prometheus-config-reloader/main.go:186\ngithub.com/oklog/run.(*Group).Run.func1\n\t/go/pkg/mod/github.com/oklog/run@v1.2.0/group.go:38\nruntime.goexit\n\t/usr/local/go/src/runtime/asm_amd64.s:1693"

      Exit Code:    1
      Started:      Sun, 19 Apr 2026 19:25:47 +0200
      Finished:     Sun, 19 Apr 2026 19:25:47 +0200
    Ready:          False
    Restart Count:  6
    Environment:
      POD_NAME:  alertmanager-monitoring-kube-prometheus-alertmanager-0 (v1:metadata.name)
      SHARD:     -1
    Mounts:
      /etc/alertmanager/config from config-volume (ro)
      /etc/alertmanager/config_out from config-out (rw)
      /etc/alertmanager/web_config/web-config.yaml from web-config (ro,path="web-config.yaml")
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-f7xk6 (ro)
Containers:
  alertmanager:
    Container ID:  
    Image:         quay.io/prometheus/alertmanager:v0.32.0
    Image ID:      
    Ports:         9093/TCP (http-web), 9094/TCP (mesh-tcp), 9094/UDP (mesh-udp)
    Host Ports:    0/TCP (http-web), 0/TCP (mesh-tcp), 0/UDP (mesh-udp)
    Args:
      --config.file=/etc/alertmanager/config_out/alertmanager.env.yaml
      --storage.path=/alertmanager
      --data.retention=120h
      --cluster.listen-address=
      --web.listen-address=:9093
      --web.external-url=http://monitoring-kube-prometheus-alertmanager.monitoring:9093
      --web.route-prefix=/
      --cluster.label=monitoring/monitoring-kube-prometheus-alertmanager
      --cluster.peer=alertmanager-monitoring-kube-prometheus-alertmanager-0.alertmanager-operated:9094
      --cluster.reconnect-timeout=5m
      --web.config.file=/etc/alertmanager/web_config/web-config.yaml
    State:          Waiting
      Reason:       PodInitializing
    Ready:          False
    Restart Count:  0
    Requests:
      memory:   200Mi
    Liveness:   http-get http://:http-web/-/healthy delay=0s timeout=3s period=10s #success=1 #failure=10
    Readiness:  http-get http://:http-web/-/ready delay=3s timeout=3s period=5s #success=1 #failure=10
    Environment:
      POD_IP:   (v1:status.podIP)
    Mounts:
      /alertmanager from alertmanager-monitoring-kube-prometheus-alertmanager-db (rw)
      /etc/alertmanager/certs from tls-assets (ro)
      /etc/alertmanager/cluster_tls_config/cluster-tls-config.yaml from cluster-tls-config (ro,path="cluster-tls-config.yaml")
      /etc/alertmanager/config from config-volume (rw)
      /etc/alertmanager/config_out from config-out (ro)
      /etc/alertmanager/web_config/web-config.yaml from web-config (ro,path="web-config.yaml")
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-f7xk6 (ro)
  config-reloader:
    Container ID:  
    Image:         quay.io/prometheus-operator/prometheus-config-reloader:v0.90.1
    Image ID:      
    Port:          8080/TCP (reloader-web)
    Host Port:     0/TCP (reloader-web)
    Command:
      /bin/prometheus-config-reloader
    Args:
      --listen-address=:8080
      --web-config-file=/etc/alertmanager/web_config/web-config.yaml
      --reload-url=http://127.0.0.1:9093/-/reload
      --config-file=/etc/alertmanager/config/alertmanager.yaml.gz
      --config-envsubst-file=/etc/alertmanager/config_out/alertmanager.env.yaml
      --watched-dir=/etc/alertmanager/config
    State:          Waiting
      Reason:       PodInitializing
    Ready:          False
    Restart Count:  0
    Environment:
      POD_NAME:  alertmanager-monitoring-kube-prometheus-alertmanager-0 (v1:metadata.name)
      SHARD:     -1
    Mounts:
      /etc/alertmanager/config from config-volume (ro)
      /etc/alertmanager/config_out from config-out (rw)
      /etc/alertmanager/web_config/web-config.yaml from web-config (ro,path="web-config.yaml")
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-f7xk6 (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 False 
  Ready                       False 
  ContainersReady             False 
  PodScheduled                True 
Volumes:
  config-volume:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  alertmanager-monitoring-kube-prometheus-alertmanager-generated
    Optional:    false
  tls-assets:
    Type:        Projected (a volume that contains injected data from multiple sources)
    SecretName:  alertmanager-monitoring-kube-prometheus-alertmanager-tls-assets-0
    Optional:    false
  config-out:
    Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:     Memory
    SizeLimit:  <unset>
  web-config:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  alertmanager-monitoring-kube-prometheus-alertmanager-web-config
    Optional:    false
  cluster-tls-config:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  alertmanager-monitoring-kube-prometheus-alertmanager-cluster-tls-config
    Optional:    false
  alertmanager-monitoring-kube-prometheus-alertmanager-db:
    Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:     
    SizeLimit:  <unset>
  kube-api-access-f7xk6:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    Optional:                false
    DownwardAPI:             true
QoS Class:                   Burstable
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason     Age                  From               Message
  ----     ------     ----                 ----               -------
  Normal   Scheduled  7m46s                default-scheduler  Successfully assigned monitoring/alertmanager-monitoring-kube-prometheus-alertmanager-0 to minikube
  Normal   Pulling    7m46s                kubelet            spec.initContainers{init-config-reloader}: Pulling image "quay.io/prometheus-operator/prometheus-config-reloader:v0.90.1"
  Normal   Pulled     6m19s                kubelet            spec.initContainers{init-config-reloader}: Successfully pulled image "quay.io/prometheus-operator/prometheus-config-reloader:v0.90.1" in 6.57s (1m26.785s including waiting). Image size: 14230502 bytes.
  Normal   Created    43s (x7 over 6m19s)  kubelet            spec.initContainers{init-config-reloader}: Container created
  Normal   Started    43s (x7 over 6m19s)  kubelet            spec.initContainers{init-config-reloader}: Container started
  Normal   Pulled     43s (x6 over 6m18s)  kubelet            spec.initContainers{init-config-reloader}: Container image "quay.io/prometheus-operator/prometheus-config-reloader:v0.90.1" already present on machine and can be accessed by the pod
  Warning  BackOff    43s (x9 over 6m17s)  kubelet            spec.initContainers{init-config-reloader}: Back-off restarting failed container init-config-reloader in pod alertmanager-monitoring-kube-prometheus-alertmanager-0_monitoring(48d5af8c-b3c0-41d5-b034-eace81f943e2)
