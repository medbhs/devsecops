Dockerfile Best Practices (TP3)

- Use official minimal base images (e.g., distroless, alpine) when appropriate.
- Pin base image versions to avoid surprises: `FROM ubuntu:24.04` or `node:20.5.0`.
- Reduce image layers: combine RUN commands where sensible.
- Avoid installing build tools in runtime images; use multi-stage builds.
- Set a non-root user and use `USER` to drop privileges.
- Minimize image size and remove package manager caches (`apt-get clean && rm -rf /var/lib/apt/lists/*`).
- Set explicit `HEALTHCHECK` for long-running services.
- Do not hardcode secrets or credentials in Dockerfile or images.
- Use COPY with specific paths rather than ADD.
- Keep images reproducible: pin apt package versions or use fixed artifacts.
- Use image labels for provenance: `LABEL maintainer=...` and `org.opencontainers.image.*` labels.
- Scan images in CI (Trivy) and fail gates for critical vulnerabilities.
