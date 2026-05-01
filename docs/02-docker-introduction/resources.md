# Docker — Resources

Useful links and references

- Official Docker docs: [docker.com/docs](https://docs.docker.com/)
- Dockerfile reference: [Dockerfile reference](https://docs.docker.com/engine/reference/builder/)
- Docker Compose: [Docker Compose docs](https://docs.docker.com/compose/)
- Multi-stage builds guide: [Multi-stage builds](https://docs.docker.com/develop/develop-images/multistage-build/)
- Best practices: [Docker best practices](https://docs.docker.com/develop/dev-best-practices/)

Cheat sheets

- Quick commands: `docker build`, `docker run`, `docker ps`, `docker images`, `docker exec`, `docker logs`, `docker-compose up`
- Dockerfile tips: order instructions for caching, copy only what you need, keep build artifacts out of final image

Examples

- Example Dockerfile (Node.js):

```dockerfile
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
```

Further reading

- Play with containers: try `docker run --rm -it alpine sh` and explore the container filesystem
- Security: avoid running as root in containers; use `USER` where possible

