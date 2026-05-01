# Lab 03 — Docker Compose Basics

Goal

- Define and run a small multi-container app using Docker Compose.

Example `docker-compose.yml`:

```yaml
version: '3.8'
services:
  web:
    build: .
    ports:
      - "8080:80"
  redis:
    image: redis:7-alpine

```

Steps

1. Create the `docker-compose.yml` above.
1. Run `docker-compose up --build` to start both services.
1. See `docker-compose ps` and view logs with `docker-compose logs -f`.

Notes

- Compose is useful for local development and testing multi-service apps.
- For production orchestration, use Kubernetes or a managed platform.
