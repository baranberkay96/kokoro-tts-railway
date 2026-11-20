# Kokoro TTS OpenAI-Compatible Speech API (API Key + Web UI): Railway template spec

## Listing

| Field | Value |
|---|---|
| Name | **Kokoro TTS OpenAI-Compatible Speech API (API Key + Web UI)** (no version label: Kokoro-FastAPI is 0.x) |
| Description | Natural text-to-speech on CPU: OpenAI /v1/audio/speech, 70+ voices. (67 chars) |
| Category | AI/ML |
| Tags | kokoro, tts, text-to-speech, openai-compatible, speech, voice, kokoro-82m, fastapi, self-hosted, api |
| Icon | `https://cdn.jsdelivr.net/gh/remsky/Kokoro-FastAPI@f2a5270…/web/favicon.svg` (200, image/svg+xml) |
| Repo | `baranberkay96/kokoro-tts-railway`, service roots `/services/gateway`, `/services/kokoro` |

## Feasibility (checked 2026-11-20)

- Licences: Kokoro-FastAPI Apache-2.0; Kokoro-82M weights Apache-2.0 (model card `license: apache-2.0`); commercial hosting allowed.
- CPU image, no GPU needed. amd64 image 1.51 GB compressed (under the 4 GB cap). Weights baked into the image; the entrypoint's download step only verifies them.
- Upstream v0.10.0 has native API keys (`API_KEYS`, Bearer / `xi-api-key` / `X-API-Key`); its web player sends no key, hence the gateway.

## Base market templates (checked 2026-11-20)

- `kokoro-tts-api` (63 active): `kokoro-fastapi-cpu:latest`, public, no auth, no thread caps.
- `kokoro-tts-lite` (25 active): third-party ONNX int8 rebuild from a user repo, optional key.
- `kokoro-tts` (6 active): `:latest` + gateway with key and basic auth; cgroup-based thread count without a cap.

### Improvements over market templates

1. API key required by default (generated), checked by Kokoro itself with a constant-time compare; web player behind a generated password; cross-site browser requests refused.
2. Pinned release (tag + index digest) instead of `:latest`.
3. Thread pools from the cgroup CPU quota, capped at 8, override `KOKORO_THREADS` (STANDARD 8.15). Measured: 8 threads on the default service.
4. Debug, model-unload and voice-saving routes off; request size capped (`MAX_INPUT_LENGTH=200000`).
5. Fail-closed handling of every deploy-form secret (STANDARD 8.29); `/` redirects to the web player.

## Pinned versions

| Component | Reference | Released | Checked |
|---|---|---|---|
| Kokoro-FastAPI (CPU) | `ghcr.io/remsky/kokoro-fastapi-cpu:v0.10.0@sha256:f54c5960c2b9387f6349080a9944f8bc7e8cdb98a4ef9238cb0b0f9ff9795f44` | 2026-11-08 | 2026-11-20 |
| Kokoro-82M | v1.0 weights, HF revision `41e5892b` (inside the image) | – | 2026-11-20 |
| Caddy | `caddy:2.11.9-alpine@sha256:003a97808e781aa9f7e75cc2f43d34d461099031faf5e20faefb9f61126836f0` | 2026-11-13 | 2026-11-20 |

## Architecture

```
API client ──https + key header──► Kokoro TTS (Caddy :8080) ──► kokoro :8880 (checks API_KEYS)
Browser ──https──► Kokoro TTS (basic auth, same-origin only) ──adds Bearer key──► kokoro :8880 (/web/)
```

## Services and variables

| Service | Source | Health | Domain | Volume |
|---|---|---|---|---|
| Kokoro TTS | repo `/services/gateway` | `/_gateway/health`, 120 s | public, 8080 | – |
| kokoro | repo `/services/kokoro` (`FROM` pinned image + wrapper) | `/health`, 600 s | private, 8880 | – |

Gateway: `KOKORO_API_KEY` (`secret(48)` alphanumeric), `KOKORO_USERNAME=kokoro`, `KOKORO_PASSWORD` (`secret(24)`), `PORT=8080`, `KOKORO_UPSTREAM`. kokoro: `KOKORO_API_KEY=${{Kokoro TTS.KOKORO_API_KEY}}` (turned into `API_KEYS=["…"]`), `PORT=8880`, `KOKORO_THREADS=auto`, `DEFAULT_VOICE=af_heart`, `USE_GPU=false`, feature switches.

## Resource profile (measured on Railway, 2026-11-20)

| Service | Idle RAM | Under load | CPU |
|---|---|---|---|
| Kokoro TTS (Caddy) | 0.02 GB | 0.02 GB | ~0 |
| kokoro | 1.06 GB | 1.23 GB | ~0 idle, ~1+ vCPU while synthesizing |

Synthesis (8 threads): 78 characters → MP3 in ~1.0 s; 947 characters (~65 s of audio) → WAV in 6.9 s.

Estimated cost idle: ~1.1 GB × $10 + small CPU ≈ **$11–13/month**. Minimum plan: **Hobby** (the model needs more than Trial's 1 GB per service; see test results).

## Test results (Railway, pre-publish, 2026-11-20)

- Deploy: both services SUCCESS, gateway health 200.
- Auth: `/` without credentials → 302 → 401; `/v1/models` without key 401, wrong key 401, wrong `xi-api-key` 401; `/v1/audio/voices` with key 200; cross-site request with basic auth 403.
- Core action: `/v1/audio/speech` with the key (MP3 and WAV) and through the signed-in browser path (MP3); `/web/` serves the player after sign-in.
- STANDARD 8.29: `KOKORO_PASSWORD=short` → deploy SUCCESS, log says LOCKED, web player 401, API with key still 200.
- STANDARD 8.31 (Trial simulation): `serviceInstanceLimitsUpdate` to 1 GB / 1 vCPU on `kokoro` → the model load is killed and the deployment FAILED (restart loop while loading weights). Hence Hobby is the stated minimum; the wrapper now logs a warning below 1.4 GB. With 1 vCPU the wrapper chose 1 thread as intended.
- At boot the upstream entrypoint verifies the baked model and fetches a small tuner config from Hugging Face; a digest mismatch there only logs a warning and the service starts.

## Verification checklist

- `https://{domain}/_gateway/health` → ok.
- `curl` the speech example from the README with the key → playable MP3.
- Sign in at `https://{domain}/` → web player plays a voice.

## Open questions

- WebSocket routes (ElevenLabs/Cartesia/OpenAI Realtime compatible) need the key in a header; browser WebSocket clients cannot send one through this gateway.
