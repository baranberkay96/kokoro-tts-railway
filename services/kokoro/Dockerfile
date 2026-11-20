# Kokoro-FastAPI (CPU) for Railway: the upstream image pinned by tag and index
# digest, plus a start wrapper that sizes thread pools from the service's CPU
# quota (not the host's cores) and turns on the API key check.
FROM ghcr.io/remsky/kokoro-fastapi-cpu:v0.10.0@sha256:f54c5960c2b9387f6349080a9944f8bc7e8cdb98a4ef9238cb0b0f9ff9795f44

USER root
COPY --chmod=0755 railway-start.sh /usr/local/bin/railway-start.sh
RUN bash -n /usr/local/bin/railway-start.sh
USER appuser

EXPOSE 8880
CMD ["/usr/local/bin/railway-start.sh"]
