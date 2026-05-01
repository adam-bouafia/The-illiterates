# Docker — Week 1 Notes

Session: Docker — From Zero to Dockerfile (25 April 2026)

Overview

- Introduction to Docker and containers
- Differences between containers and VMs
- Docker architecture. Covers the daemon, images, containers, and registries.
Key concepts

- Images
- Containers
- Layers
- Registries
- Volumes
- Networks
Core concepts

- Container: process-isolated runtime.
- Image — an immutable, layered filesystem used to create containers.
- Layering: Each Dockerfile instruction creates a new image layer.
- Registry: A place to push/pull images (Docker Hub, private registries).
- Volumes: Persistent storage mounted into containers.

Dockerfile anatomy (quick reference)

- `FROM <image>` — base image
- `LABEL` — metadata
- `RUN` — execute commands at build time
- `COPY` — add files into image (prefer `COPY`)
- `EXPOSE` — document ports
- `ENV` — set environment variables
- `CMD` / `ENTRYPOINT` — runtime command

Best practices (high level)

- Prefer small base images (alpine, slim) when useful.
- Use multi-stage builds for smaller final images.
- Pin base image versions (avoid: `FROM node:latest`).
- Reduce number of layers and combine `RUN` steps when sensible.
- Keep secrets out of images; inject them at runtime (env, secrets).

Essential commands

- `docker build -t myapp:1.0 .`
- `docker run --rm -p 8080:80 myapp:1.0`
- `docker ps`, `docker images`, `docker logs <container>`
- `docker exec -it <container> /bin/sh`
- `docker pull`, `docker push`

Multi-stage build example (concept)

- Build stage: compile app and produce artifacts
- Final stage: copy artifacts into minimal runtime image

Docker Compose (bonus)

- Compose defines multi-container apps with `docker-compose.yml`
- `docker-compose up --build` builds images and starts services

References

- See resources page for links and examples.
