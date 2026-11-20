# NOTICE: Kokoro TTS OpenAI-Compatible Speech API template

## Software deployed

- **Kokoro-FastAPI** by remsky and contributors, Apache License 2.0, https://github.com/remsky/Kokoro-FastAPI. Deployed unmodified from the official image `ghcr.io/remsky/kokoro-fastapi-cpu:v0.10.0` (pinned by digest).
- **Kokoro-82M** model and voices by hexgrad, Apache License 2.0, https://huggingface.co/hexgrad/Kokoro-82M (licence checked on the model card, 2026-11-20). The weights are part of the upstream image (downloaded at its build from the pinned Hugging Face revision `41e5892b`).
- **Caddy** 2.11.9, Apache License 2.0, https://github.com/caddyserver/caddy, official image `caddy:2.11.9-alpine` (pinned by digest).
- The upstream image also contains espeak-ng (GPL-3.0) as the phonemizer, unmodified.

## Written for this template

- `services/kokoro/Dockerfile`, `services/kokoro/railway-start.sh`: CPU-quota thread sizing and the API key setting; they call the image's own `entrypoint.sh`.
- `services/gateway/*`: Caddy configuration and start script (basic auth for browsers, API-key pass-through), adapted from our own Bytebot template gateway.
- `README.md`, `TEMPLATE.md`, `template.json`.

## Upstream files checked (read only, 2026-11-20)

- `docker/cpu/Dockerfile.optimized`, `docker/scripts/entrypoint.sh`, `docker/scripts/download_model.py`, `api/src/core/config.py`, `api/src/core/auth.py`, `api/src/main.py`, `docs/configuration.md` at tag `v0.10.0`.

## Market templates reviewed

`kokoro-tts-api`, `kokoro-tts-lite`, `kokoro-tts` (configuration only; nothing copied).

## Names and affiliation

Community template, not affiliated with the Kokoro or Kokoro-FastAPI authors. "OpenAI-compatible" describes the API format only. The icon is Kokoro-FastAPI's own web player favicon.
