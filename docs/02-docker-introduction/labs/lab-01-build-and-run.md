
# Lab 01 — Build and Run a Small Image

Goal

- Build a minimal container image for a small web app and run it locally.

Steps

1. Create a minimal app (example uses a static HTML file):

```sh
mkdir lab1 && cd lab1
cat > index.html <<'HTML'
<h1>Hello from Docker Lab 1</h1>
HTML
```

1. Add an example Dockerfile:

```dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
```

1. Build and run the image:

```sh
docker build -t lab1-example .
docker run --rm -p 8080:80 lab1-example
# then open http://localhost:8080
```

1. See running containers and logs:

```sh
docker ps
docker logs <container-id>
docker exec -it <container-id> sh
```

Cleanup

```sh
docker rm -f <container-id> || true
docker image rm lab1-example || true
```
