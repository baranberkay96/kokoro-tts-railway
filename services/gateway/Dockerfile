# Kokoro TTS gateway: Caddy with basic auth for the web player and API-key
# pass-through for API clients. The official Caddy image, pinned by tag and digest.
FROM caddy:2.11.9-alpine@sha256:003a97808e781aa9f7e75cc2f43d34d461099031faf5e20faefb9f61126836f0

COPY Caddyfile /etc/caddy/Caddyfile
COPY --chmod=0755 railway-gateway.sh /usr/local/bin/railway-gateway.sh

# Fail the build rather than the deploy on a Caddyfile error.
RUN sh -n /usr/local/bin/railway-gateway.sh \
 && PORT=8080 BASIC_AUTH_USERNAME=check KOKORO_API_KEY=check-key-check-key \
    BASIC_AUTH_HASH='$2a$14$abcdefghijklmnopqrstuuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0' \
    KOKORO_UPSTREAM=kokoro.railway.internal:8880 \
    caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/railway-gateway.sh"]
CMD []
