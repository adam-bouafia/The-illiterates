# Lab 02 — Dockerfile Anatomy and Multi-stage Builds

Goal

- Learn the meaning of common Dockerfile instructions and create a multi-stage build.

Example (multi-stage Go app simplified):

```dockerfile
FROM golang:1.20-alpine AS build
WORKDIR /src
COPY . .
RUN go build -o /app/myapp ./...

FROM alpine:latest
COPY --from=build /app/myapp /usr/local/bin/myapp
ENTRYPOINT ["/usr/local/bin/myapp"]
```

Notes

- Use `COPY --from=` to copy artifacts from build stages
- Keep runtime image minimal (no compilers or build tools)
- Combine `RUN` commands to reduce layers when useful

Tasks

- Convert a small app into a multi-stage Dockerfile and verify final image size with `docker images`
